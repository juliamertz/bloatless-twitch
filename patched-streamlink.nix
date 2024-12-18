{
  python3Packages,
  fetchFromGitHub,
  fetchpatch,
}:
let
  streamlink-ttvlol-patch =
    let
      repo = "2bc4/streamlink-ttvlol";
      rev = "e0acf425ceeb7daa5aaceaed71e43da3d6241091";
    in
    fetchpatch {
      url = "https://raw.githubusercontent.com/${repo}/refs/heads/${rev}/streamlink-ttvlol.patch";
      sha256 = "sha256-bMc5CBUCCHXB6Qox56xqwEdplbfw58dowyiX54ptLlw=";
    };
in
python3Packages.buildPythonApplication {
  pname = "streamlink";
  version = "6.11.0";
  pyproject = true;

  patches = [ streamlink-ttvlol-patch ];
  src = fetchFromGitHub {
    owner = "streamlink";
    repo = "streamlink";
    rev = "16a1d84386539c8c8e480b73a519e179fcb8703c";
    sha256 = "sha256-nRBJ/w4JCmProdjDVqfJP58fmyV6H7nmvUB9FdBpL7s=";
  };

  nativeBuildInputs = with python3Packages; [
    setuptools
    versioningit
  ];

  nativeCheckInputs = with python3Packages; [
    mock
    requests-mock
    freezegun
    pytest-trio
  ];

  propagatedBuildInputs = with python3Packages; [
    certifi
    isodate
    lxml
    pycountry
    pycryptodome
    pysocks
    requests
    trio
    trio-websocket
    typing-extensions
    urllib3
    websocket-client
  ];

  meta = {
    mainProgram = "streamlink";
  };
}
