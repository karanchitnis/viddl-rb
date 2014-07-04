
class FormatPicker

  Format = Struct.new(:itag, :extension, :resolution, :name)
  Resolution = Struct.new(:width, :height)

  # see http://en.wikipedia.org/wiki/YouTube#Quality_and_codecs
  # TODO: we don't have all the formats from the wiki article here
  # :u means the resolution is unknown.
  FORMATS = [
    Format.new("38",  "mp4",   Resolution.new(4096, 3027),  "MP4 Highest Quality 4096x3027 (H.264, AAC)"),
    Format.new("37",  "mp4",   Resolution.new(1920, 1080),  "MP4 Highest Quality 1920x1080 (H.264, AAC)"),
    Format.new("22",  "mp4",   Resolution.new(1280, 720),   "MP4 1280x720 (H.264, AAC)"),
    Format.new("46",  "mp4",   Resolution.new(1920, 1080),  "MP4 1920x1080 (H.264, AAC)"),
    Format.new("45",  "mp4",   Resolution.new(1280, 720),   "MP4 1280x720 (H.264, AAC)"),
    Format.new("44",  "mp4",   Resolution.new(854, 480),    "MP4 854x480 (H.264, AAC)"),
    Format.new("43",  "mp4",   Resolution.new(480, 360),    "MP4 480x360 (H.264, AAC)"),
    Format.new("18",  "mp4",   Resolution.new(640, 360),    "MP4 640x360 (H.264, AAC)"),
    Format.new("35",  "mp4",   Resolution.new(854, 480),    "MP4 854x480 (H.264, AAC)"),
    Format.new("34",  "mp4",   Resolution.new(640, 360),    "MP4 640x360 (H.264, AAC)"),
    Format.new("6",   "mp4",   Resolution.new(640, 360),    "MP4 640x360 (H.264, AAC)"),
    Format.new("5",   "mp4",   Resolution.new(400, 240),    "MP4 400x240 (H.264, AAC)"),
    Format.new("36",  "mp4",   Resolution.new(320, 240),    "MP4 320x240 (H.264, AAC)"),
    Format.new("17",  "mp4",   Resolution.new(174, 144),    "MP4 176x144 (H.264, AAC)"),
    Format.new("13",  "mp4",   Resolution.new(176, 144),    "MP4 176x144 (H.264, AAC)"),
    Format.new("82",  "mp4",   Resolution.new(480, 360),    "MP4 360p (H.264 AAC)"),
    Format.new("83",  "mp4",   Resolution.new(320, 240),    "MP4 240p (H.264 AAC)"),
    Format.new("84",  "mp4",   Resolution.new(1280, 720),   "MP4 720p (H.264 AAC)"),
    Format.new("85",  "mp4",   Resolution.new(960, 520),    "MP4 520p (H.264 AAC)"),
    Format.new("100", "mp4",   Resolution.new(480, 360),    "MP4 360p (H.264)"),
    Format.new("101", "mp4",   Resolution.new(480, 360),    "MP4 360p (H.264)"),
    Format.new("102", "mp4",   Resolution.new(1280, 720),   "MP4 720p (H.264)"),
    Format.new("120", "mp4",   Resolution.new(1280, 720),   "MP4 720p (H.264)"),
    Format.new("133", "mp4",   Resolution.new(320, 240),    "MP4 240p (H.264)"),
    Format.new("134", "mp4",   Resolution.new(480, 360),    "MP4 360p (H.264)"),
    Format.new("135", "mp4",   Resolution.new(640, 480),    "MP4 480p (H.264)"),
    Format.new("136", "mp4",   Resolution.new(1280, 720),   "MP4 720p (H.264)"),
    Format.new("137", "mp4",   Resolution.new(1920, 1080),  "MP4 1080p (H.264)"),
    Format.new("139", "mp4",   Resolution.new(:u, :u),      "MP4 (AAC)"),
    Format.new("140", "mp4",   Resolution.new(:u, :u),      "MP4 (AAC"),
    Format.new("141", "mp4",   Resolution.new(:u, :u),      "MP4 (AAC)"),
    Format.new("160", "mp4",   Resolution.new(:u, :u),      "MP4 (H.264)"),
    Format.new("171", "mp4",   Resolution.new(:u, :u),      "MP4 (H.264)"),
    Format.new("172", "mp4",   Resolution.new(:u, :u),      "MP4 (H.264)")
  ]

  DEFAULT_FORMAT_ORDER = %w[38 37 22 46 45 44 43 18 35 34 6 5 36 17 13 82 83 84 85 100 101 102 120 133 134 135 136 137 139 140 141 160 171 172]
  #DEFAULT_FORMAT_ORDER = %w[38 37 22 18 82 83 84 85 133 134 135 136 137 139 140 141 160]

  def initialize(options)
    @options = options
  end

  def pick_format(video)
    if quality = @options[:quality]
      get_quality_format(video, quality)
    else
      get_default_format_for_video(video)
    end
  end

  private

  def get_default_format_for_video(video)
    available = get_available_formats_for_video(video)
    get_default_format(available)
  end

  def get_available_formats_for_video(video)
    video.available_itags.map { |itag| get_format_by_itag(itag) }
  end

  def get_format_by_itag(itag)
    FORMATS.find { |format| format.itag == itag }
  end

  def get_default_format(formats)
    DEFAULT_FORMAT_ORDER.each do |itag|
      default_format = formats.find { |format| format.itag == itag }
      return default_format if default_format
    end
    nil
  end

  def get_quality_format(video, quality)
    available = get_available_formats_for_video(video) 

    matches = available.select do |format|
      matches_extension?(format, quality) && matches_resolution?(format, quality)
    end

    select_format(video, matches)
  end

  def matches_extension?(format, quality)
    return false if quality[:extension] && quality[:extension] != format.extension
    true
  end

  def matches_resolution?(format, quality)
    return false if quality[:width] && quality[:width] != format.resolution.width
    return false if quality[:height] && quality[:height] != format.resolution.height
    true
  end

  def select_format(video, formats)
    case formats.length
    when 0
      Youtube.notify "Requested format not found. Downloading default format."
      get_default_format_for_video(video)
    when 1
      formats.first
    else
      get_default_format(formats)
    end
  end
end
