class CardBuilderService
  include Prawn::View

  def initialize(card_id, album_format_id)
    @card = Card.find(card_id)
    @photoalbum = @card.photoalbum
    @cover = @photoalbum.cover
    @framed_photos = @cover.framed_photos
    @format = Photoalbums::AlbumFormat.find(album_format_id)
    @album_type = @format.album_type
    @joint = @format.paper_thickness * @photoalbum.spreads_count + @album_type.k_coef
    @joint = [@joint, @format.min_otstav_width].max
    # См картинку в тех. задании, чтобы понять всякие величины тут
    @carton_width = @format.carton_width.mm
    @carton_height = @format.carton_height.mm
    @separation_width = @format.rasstav_width.mm
    @min_joint_width = @format.min_otstav_width.mm
    @valves_width = @format.valve_width.mm
    @page_width = (@format.valve_width * 2 + @format.carton_width * 2 + @format.rasstav_width * 2 + @joint).mm
    @page_height = (@format.valve_width * 2 + @format.carton_height).mm
    @y = @page_height - @valves_width
    # Тут координаты "х" у тех или иных объектов на обложке, для удобства
    @left_carton_x = @valves_width
    @left_separation_x = @valves_width + @carton_width
    @joint_x = @valves_width + @carton_width + @separation_width
    @right_separation_x = @valves_width + @carton_width + @separation_width + @min_joint_width
    @right_carton_x = @valves_width + @carton_width + @separation_width * 2 + @min_joint_width
    # Захардкожено с начала, тк нет точной информации, как считать рабочую зону, а Игорь не говорил
    @zone = 183.mm
  end

  def generate
    @pdf = Prawn::Document.new(page_size: [@page_height, @page_width], margin: 0,
                               page_layout: :landscape)
    generate_backgrounds
    # generate_corners
    generate_frames
    generate_qrcode
    generate_tech_marks
    @pdf.render_file File.join(Rails.root, 'tmp', pdf_name)
    @photoalbum.pdfs << Photoalbums::Pdf.create(file: File.open("#{Rails.root}/tmp/#{pdf_name}"), album_format_id: @format.id)
    File.delete("#{Rails.root}/tmp/#{pdf_name}") if File.exist?("#{Rails.root}/tmp/#{pdf_name}")
  end

  private

  def generate_corners
    # эта штука должна рисовать границы полей на pdf, чисто для отладки
    @pdf.stroke_rectangle [@left_carton_x, @y], @carton_width, @carton_height
    @pdf.stroke_rectangle [@left_separation_x, @y], @separation_width, @carton_height
    @pdf.stroke_rectangle [@joint_x, @y], @min_joint_width, @carton_height
    @pdf.stroke_rectangle [@right_separation_x, @y], @separation_width, @carton_height
    @pdf.stroke_rectangle [@right_carton_x, @y], @carton_width, @carton_height
  end

  def generate_frames
    frame_place_x = 5.mm + @right_carton_x # хардкод, не было инфы
    frame_place_y = @valves_width + @carton_height - 10.mm # same
    # заполняем рамки и вставляем в обложку
    @framed_photos.each do |framed_photo|
      frame = framed_photo.frame
      photo = framed_photo.photo
      frame_size_mm = frame_size(frame)
      x = frame_place_x + @zone * (frame.x - 50) / 50
      y = frame_place_y - @zone * frame.y / 50
      top_left_x = frame_place_x + @zone * (frame.top_left_x - 50) / 50
      top_left_y = frame_place_y - @zone * frame.top_left_y / 50
      # если в рамке текст, то вставляем и проходим дальше
      if photo.blank?
        draw_text(framed_photo, top_left_x, top_left_y, frame_size_mm[0], frame_size_mm[1])
        next
      end
      photo_size_mm = image_size(frame, photo)
      frame_size_photo = frame_size_crop(frame, photo)
      change_image_color_profile(photo.image.url(:original, timestamp: false))
      image = MiniMagick::Image.open(add_host_prefix(photo.image.url(:original, timestamp: false)))
      image.rotate framed_photo.rotation.to_s
      # scaling_picture(framed_photo, photo, image, frame_size_mm[0], frame_size_mm[1], photo_size_mm[0], photo_size_mm[1])
      cropping_picture(framed_photo, photo, image, frame_size_photo[0], frame_size_photo[1], photo.width.to_d, photo.height.to_d)
      image.scale '417%' # Единственный способ сделать фотки в 300 DPI, который у меня заработал,
      # это увеличить картинку, а при вставке в PDF сжать
      image.write 'frame.jpg'
      scale = 0.239
      @pdf.rotate(360 - frame.angle, origin: [x, y]) do
        @pdf.image open('frame.jpg'), at: [top_left_x, top_left_y], scale: 0.239
      end
      File.delete('frame.jpg') if File.exist?('frame.jpg')
    end
  end

  def generate_backgrounds
    image = MiniMagick::Image.open(add_host_prefix(@cover.cover_background.image.image.url(:original, timestamp: false)))
    image.resize "#{@page_width}x#{@page_height}^"
    image.scale '417%' # Единственный способ сделать фотки в 300 DPI, который у меня заработал,
    # это увеличить картинку, а при вставке в PDF сжать
    image.write 'bg.jpg'
    change_background_color_profile('bg.jpg')
    @pdf.image open('bg.jpg'), at: [0, @page_height], scale: 0.239
    File.delete('bg.jpg') if File.exist?('bg.jpg')
  end

  def generate_qrcode
    # Эти отступы нужно подхватывать из album_format.qrcode
    frame_place_x = 10.mm + @left_carton_x
    frame_place_y = @valves_width + @carton_height - 10.mm
    # @pdf.stroke_rectangle [frame_place_x, frame_place_y], @zone, @zone
    link = Setting[:qr_code_link]
    image = MiniMagick::Image.read(Pdf::QrcodeService.new(link, 20.mm).generate)
    image.write 'qr.jpg'
    @pdf.image open('qr.jpg'), at: [frame_place_x + 183.mm / 2 - 20.mm / 2, frame_place_y - 140.mm]
    File.delete('qr.jpg') if File.exist?('qr.jpg')
  end

  def generate_tech_marks
    # Технологические метки, захардкожено, тк не было величин
    @pdf.stroke_line [@page_width / 2, @page_height - 7.mm], [@page_width / 2, @page_height - 13.mm]
    @pdf.stroke_line [@page_width / 2 - @min_joint_width / 2, @page_height - 13.mm], [@page_width / 2 + @min_joint_width / 2, @page_height - 13.mm]

    @pdf.stroke_line [@page_width / 2, 7.mm], [@page_width / 2, 13.mm]
  end

  def image_size(frame, photo)
    frame_width_mm = frame_size(frame)[0]
    frame_height_mm = frame_size(frame)[1]
    frame_ratio = frame_width_mm / frame_height_mm
    photo_ratio = photo.width.to_d / photo.height.to_d
    if frame_ratio < photo_ratio
      photo_height = frame_height_mm
      photo_width = photo_height * photo_ratio
    else
      photo_width = frame_width_mm
      photo_height = photo_width / photo_ratio
    end
    [photo_width, photo_height]
  end

  def frame_size_crop(frame, photo)
    frame_width_mm = frame.width
    frame_height_mm = frame.height
    frame_ratio = frame_width_mm / frame_height_mm
    photo_ratio = photo.width.to_d / photo.height.to_d
    if frame_ratio < photo_ratio
      frame_height = photo.height.to_d
      frame_width = frame_height * frame_ratio
    else
      frame_width = photo.width.to_d
      frame_height = frame_width / frame_ratio
    end
    [frame_width, frame_height]
  end

  def frame_size(frame)
    frame_width_mm = frame.width * @zone / 50
    frame_height_mm = frame.height * @zone / 50
    [frame_width_mm, frame_height_mm]
  end

  def scaling_picture(framed_photo, _photo, image, frame_width_mm, frame_height_mm, photo_width_mm, photo_height_mm)
    image.resize "#{photo_width_mm * framed_photo.scale}x#{photo_height_mm * framed_photo.scale}>"
    dx = framed_photo.rotated_x * photo_width_mm / 100
    dy = framed_photo.rotated_y * photo_height_mm / 100
    cx = photo_width_mm / 2 - dx - frame_width_mm / 2
    cy = photo_height_mm / 2 - dy - frame_height_mm / 2
    image.crop "#{frame_width_mm}x#{frame_height_mm}+#{cx}+#{cy}"
  end

  def cropping_picture(framed_photo, _photo, image, frame_width_mm, frame_height_mm, photo_width_mm, photo_height_mm)
    dx = framed_photo.rotated_x * photo_width_mm / 100
    dy = framed_photo.rotated_y * photo_height_mm / 100
    cx = photo_width_mm / 2 - dx - frame_width_mm / 2
    cy = photo_height_mm / 2 - dy - frame_height_mm / 2
    image.crop "#{frame_width_mm}x#{frame_height_mm}+#{cx}+#{cy}"
  end

  def draw_text(framed_photo, x, y, width, height)
    # "koef dlya texta: 0.025, a potom umnozhit' na @zone", это спрашивай у Артема, почему так
    @pdf.font("#{Rails.root}/public#{@cover.cover_background.font.font.url(:original, timestamp: false)}") do
      @pdf.fill_color @cover.cover_background.font_color[1..-1].upcase.to_s
      @pdf.text_box framed_photo.text, at: [x, y], width: width, height: height, size: framed_photo.text_size / 100 * 0.025 * @zone * 2,
                                       rotate: 360 - framed_photo.frame.angle, rotate_around: :center, align: :center
    end
  end

  def pdf_name
    "Cov#{@card.pretty_id + @format.album_type.initials}.pdf"
  end
end

end