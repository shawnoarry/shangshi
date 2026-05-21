param(
  [Parameter(Mandatory = $true)][string]$InputDir,
  [Parameter(Mandatory = $true)][string]$OutText,
  [Parameter(Mandatory = $true)][string]$OutJsonl,
  [string]$Language = "zh-Hans-CN"
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
$null = [Windows.Storage.Streams.IRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime]
$null = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType = WindowsRuntime]
$null = [Windows.Graphics.Imaging.SoftwareBitmap, Windows.Graphics.Imaging, ContentType = WindowsRuntime]
$null = [Windows.Graphics.Imaging.BitmapPixelFormat, Windows.Graphics.Imaging, ContentType = WindowsRuntime]
$null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime]
$null = [Windows.Globalization.Language, Windows.Foundation, ContentType = WindowsRuntime]

$asTask = @(
  [System.WindowsRuntimeSystemExtensions].GetMethods() |
    Where-Object {
      $_.Name -eq "AsTask" -and
      $_.IsGenericMethod -and
      $_.GetParameters().Count -eq 1 -and
      $_.GetParameters()[0].ParameterType.Name -eq "IAsyncOperation``1"
    }
)[0]

function Wait-WinRtOperation($operation, [Type]$resultType) {
  $task = $asTask.MakeGenericMethod($resultType).Invoke($null, [object[]]@($operation))
  $task.Wait()
  return $task.Result
}

function Convert-ToJsonLine([hashtable]$data) {
  return ($data | ConvertTo-Json -Compress -Depth 4)
}

$engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage([Windows.Globalization.Language]::new($Language))
if ($null -eq $engine) {
  throw "OCR language is not available: $Language"
}

$pages = Get-ChildItem -LiteralPath $InputDir -Filter "page-*.png" |
  Sort-Object Name

$textParts = New-Object System.Collections.Generic.List[string]
$jsonLines = New-Object System.Collections.Generic.List[string]

foreach ($pageFile in $pages) {
  $pageNumber = [int]([regex]::Match($pageFile.BaseName, "\d+").Value)
  $stream = $null
  $bitmap = $null
  try {
    $file = Wait-WinRtOperation ([Windows.Storage.StorageFile]::GetFileFromPathAsync($pageFile.FullName)) ([Windows.Storage.StorageFile])
    $stream = Wait-WinRtOperation ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
    $decoder = Wait-WinRtOperation ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
    $bitmap = Wait-WinRtOperation ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])

    if (
      $bitmap.BitmapPixelFormat -ne [Windows.Graphics.Imaging.BitmapPixelFormat]::Bgra8 -and
      $bitmap.BitmapPixelFormat -ne [Windows.Graphics.Imaging.BitmapPixelFormat]::Gray8
    ) {
      $converted = [Windows.Graphics.Imaging.SoftwareBitmap]::Convert($bitmap, [Windows.Graphics.Imaging.BitmapPixelFormat]::Bgra8)
      $bitmap.Dispose()
      $bitmap = $converted
    }

    $result = Wait-WinRtOperation ($engine.RecognizeAsync($bitmap)) ([Windows.Media.Ocr.OcrResult])
    $text = ($result.Text -replace "\s+", " ").Trim()
    $textParts.Add("--- Page $pageNumber ---`n$text")
    $jsonLines.Add((Convert-ToJsonLine @{ page = $pageNumber; text = $text }))

    if ($pageNumber % 20 -eq 0 -or $pageNumber -eq $pages.Count) {
      Write-Host "OCR page $pageNumber/$($pages.Count)"
    }
  } finally {
    if ($null -ne $bitmap) { $bitmap.Dispose() }
    if ($null -ne $stream) { $stream.Dispose() }
  }
}

Set-Content -LiteralPath $OutText -Value ($textParts -join "`n`n") -Encoding UTF8
Set-Content -LiteralPath $OutJsonl -Value ($jsonLines -join "`n") -Encoding UTF8
