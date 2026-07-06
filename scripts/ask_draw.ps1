param(
  [ValidateSet("classic", "portrait", "square", "ultrawide", "wide")]
  [string]$Type = "",

  [string]$Prompt = "",

  [string[]]$Ref = @(),

  [string]$Frame = "",

  [string]$Name = "",

  [Alias("o")]
  [string]$Output = "",

  [string]$Model = "",

  [string]$BaseUrl = "",

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$ExtraArgs
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$VenvDir = if ($env:DRAW_VENV) { $env:DRAW_VENV } else { Join-Path $HOME ".cache\draw\venv" }
$PythonBin = $env:DRAW_PYTHON

if (-not $PythonBin) {
  $UnixPython = Join-Path $VenvDir "bin\python3"
  $WindowsPython = Join-Path $VenvDir "Scripts\python.exe"
  if (Test-Path -LiteralPath $WindowsPython) {
    $PythonBin = $WindowsPython
  } elseif (Test-Path -LiteralPath $UnixPython) {
    $PythonBin = $UnixPython
  } else {
    $PythonBin = $WindowsPython
  }
}

$SystemPython = $env:DRAW_SYSTEM_PYTHON
if (-not $SystemPython) {
  $PythonCommand = Get-Command python -ErrorAction SilentlyContinue
  if ($PythonCommand) {
    $SystemPython = $PythonCommand.Source
  } else {
    throw "Python not found. Install Python 3 or set DRAW_SYSTEM_PYTHON."
  }
}

if (-not (Test-Path -LiteralPath $PythonBin)) {
  New-Item -ItemType Directory -Force -Path $VenvDir | Out-Null
  & $SystemPython -m venv $VenvDir
}

if (-not (Test-Path -LiteralPath $PythonBin)) {
  $WindowsPython = Join-Path $VenvDir "Scripts\python.exe"
  if (Test-Path -LiteralPath $WindowsPython) {
    $PythonBin = $WindowsPython
  }
}

if (-not (Test-Path -LiteralPath $PythonBin)) {
  throw "Could not find virtualenv Python at $PythonBin. Set DRAW_PYTHON to override."
}

& $PythonBin -c "import google.genai, PIL" *> $null
if ($LASTEXITCODE -ne 0) {
  & $PythonBin -m pip install --quiet --upgrade pip google-genai pillow
}

$ForwardArgs = New-Object System.Collections.Generic.List[string]
if ($Frame) {
  $ForwardArgs.Add("--ref")
  $ForwardArgs.Add($Frame)
}
foreach ($RefPath in $Ref) {
  $ForwardArgs.Add("--ref")
  $ForwardArgs.Add($RefPath)
}
if ($Type) {
  $ForwardArgs.Add("--type")
  $ForwardArgs.Add($Type)
}
if ($Prompt) {
  $ForwardArgs.Add("--prompt")
  $ForwardArgs.Add($Prompt)
}
if ($Name) {
  $ForwardArgs.Add("--name")
  $ForwardArgs.Add($Name)
}
if ($Output) {
  $ForwardArgs.Add("--output")
  $ForwardArgs.Add($Output)
}
if ($Model) {
  $ForwardArgs.Add("--model")
  $ForwardArgs.Add($Model)
}
if ($BaseUrl) {
  $ForwardArgs.Add("--base-url")
  $ForwardArgs.Add($BaseUrl)
}
foreach ($Arg in $ExtraArgs) {
  $ForwardArgs.Add($Arg)
}

$GenerateScript = Join-Path $ScriptDir "generate_image.py"
& $PythonBin $GenerateScript @ForwardArgs
exit $LASTEXITCODE
