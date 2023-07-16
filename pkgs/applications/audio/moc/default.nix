{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  ncurses,
  db,
  popt,
  libtool,
  libiconv,
  CoreServices
  # Sound sub-systems
  ,
  alsaSupport ? (!stdenv.isDarwin),
  alsa-lib,
  pulseSupport ? true,
  libpulseaudio,
  autoreconfHook,
  jackSupport ? true,
  libjack2,
  ossSupport ? true
  # Audio formats
  ,
  aacSupport ? true,
  faad2,
  libid3tag,
  flacSupport ? true,
  flac,
  midiSupport ? true,
  timidity,
  modplugSupport ? true,
  libmodplug,
  mp3Support ? true,
  libmad,
  musepackSupport ? true,
  libmpc,
  libmpcdec,
  taglib,
  vorbisSupport ? true,
  libvorbis,
  speexSupport ? true,
  speex,
  ffmpegSupport ? true,
  ffmpeg_4,
  sndfileSupport ? true,
  libsndfile,
  wavpackSupport ? true,
  wavpack
  # Misc
  ,
  curlSupport ? true,
  curl,
  samplerateSupport ? true,
  libsamplerate,
  withDebug ? false
}:

stdenv.mkDerivation rec {

  pname = "moc";
  version = "2.5.2";

  src = fetchurl {
    url = "http://ftp.daper.net/pub/soft/moc/stable/moc-${version}.tar.bz2";
    sha256 = "026v977kwb0wbmlmf6mnik328plxg8wykfx9ryvqhirac0aq39pk";
  };

  patches =
    [ ]
    ++ lib.optional ffmpegSupport ./moc-ffmpeg4.patch
    ++ lib.optional pulseSupport ./pulseaudio.patch
    ;

  nativeBuildInputs =
    [ pkg-config ] ++ lib.optional pulseSupport autoreconfHook;

  buildInputs =
    [
      ncurses
      db
      popt
      libtool
    ]
    # Sound sub-systems
    ++ lib.optional alsaSupport alsa-lib
    # Sound sub-systems
    ++ lib.optional pulseSupport libpulseaudio
    # Sound sub-systems
    ++ lib.optional jackSupport libjack2
    # Sound sub-systems
    ++ lib.optional (aacSupport || mp3Support) libid3tag
    # Sound sub-systems
    ++ lib.optional aacSupport faad2
    # Sound sub-systems
    ++ lib.optional flacSupport flac
    # Sound sub-systems
    ++ lib.optional midiSupport timidity
    # Sound sub-systems
    ++ lib.optional modplugSupport libmodplug
    # Sound sub-systems
    ++ lib.optional mp3Support libmad
    # Sound sub-systems
    ++ lib.optionals musepackSupport [
      libmpc
      libmpcdec
      taglib
    ]
    # Sound sub-systems
    ++ lib.optional vorbisSupport libvorbis
    # Sound sub-systems
    ++ lib.optional speexSupport speex
    # Sound sub-systems
    ++ lib.optional ffmpegSupport ffmpeg_4
    # Sound sub-systems
    ++ lib.optional sndfileSupport libsndfile
    # Sound sub-systems
    ++ lib.optional wavpackSupport wavpack
    # Sound sub-systems
    ++ lib.optional curlSupport curl
    # Sound sub-systems
    ++ lib.optional samplerateSupport libsamplerate
    # Sound sub-systems
    ++ lib.optionals stdenv.isDarwin [
      libiconv
      CoreServices
    ]
    ;

  configureFlags = [
    # Sound sub-systems
    (lib.withFeature alsaSupport "alsa")
    (lib.withFeature pulseSupport "pulse")
    (lib.withFeature jackSupport "jack")
    (lib.withFeature ossSupport "oss")
    # Audio formats
    (lib.withFeature aacSupport "aac")
    (lib.withFeature flacSupport "flac")
    (lib.withFeature midiSupport "timidity")
    (lib.withFeature modplugSupport "modplug")
    (lib.withFeature mp3Support "mp3")
    (lib.withFeature musepackSupport "musepack")
    (lib.withFeature vorbisSupport "vorbis")
    (lib.withFeature speexSupport "speex")
    (lib.withFeature ffmpegSupport "ffmpeg")
    (lib.withFeature sndfileSupport "sndfile")
    (lib.withFeature wavpackSupport "wavpack")
    # Misc
    (lib.withFeature curlSupport "curl")
    (lib.withFeature samplerateSupport "samplerate")
    (
      "--enable-debug="
      + (
        if withDebug then
          "yes"
        else
          "no"
      )
    )
    "--disable-cache"
    "--without-rcc"
  ];

  meta = with lib; {
    description =
      "An ncurses console audio player designed to be powerful and easy to use";
    homepage = "http://moc.daper.net/";
    license = licenses.gpl2;
    maintainers = with maintainers; [
      aethelz
      pSub
      jagajaga
    ];
    platforms = platforms.unix;
  };
}
