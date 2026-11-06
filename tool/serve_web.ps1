# Lumora static web preview server.
# Serves build/web on http://127.0.0.1:8080 using a raw TcpListener so it
# works without admin rights or URL ACL registration.
$ErrorActionPreference = 'Continue'

$root = Join-Path $PSScriptRoot '..\build\web'
$root = [System.IO.Path]::GetFullPath($root)

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 8080)
$listener.Start()
Write-Output "LUMORA STATIC SERVER LISTENING http://127.0.0.1:8080/ root=$root"

$mime = @{
  '.html' = 'text/html; charset=utf-8'
  '.js'   = 'application/javascript'
  '.mjs'  = 'application/javascript'
  '.css'  = 'text/css; charset=utf-8'
  '.json' = 'application/json'
  '.png'  = 'image/png'
  '.jpg'  = 'image/jpeg'
  '.svg'  = 'image/svg+xml'
  '.ico'  = 'image/x-icon'
  '.ttf'  = 'font/ttf'
  '.otf'  = 'font/otf'
  '.woff' = 'font/woff'
  '.woff2'= 'font/woff2'
  '.wasm' = 'application/wasm'
  '.map'  = 'application/json'
}

while ($true) {
  try {
    $client = $listener.AcceptTcpClient()
    $stream = $client.GetStream()
    $reader = [System.IO.StreamReader]::new($stream)
    $requestLine = $reader.ReadLine()
    if ($null -eq $requestLine) { $client.Close(); continue }

    # Drain remaining request headers.
    while (-not [string]::IsNullOrWhiteSpace($reader.ReadLine())) { }

    $path = ($requestLine -split ' ')[1]
    if ($path -eq '/') { $path = '/index.html' }
    $path = [Uri]::UnescapeDataString($path) -replace '/', '\'
    $file = Join-Path $root $path.TrimStart('\')

    # Prevent path traversal.
    if (-not $file.StartsWith($root)) {
      $bytes = [System.Text.Encoding]::UTF8.GetBytes("HTTP/1.1 403 Forbidden`r`nContent-Length: 0`r`nConnection: close`r`n`r`n")
      $stream.Write($bytes, 0, $bytes.Length)
      $client.Close()
      continue
    }

    if (Test-Path $file -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
      $type = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
      $bytes = [System.IO.File]::ReadAllBytes($file)
      $header = "HTTP/1.1 200 OK`r`nContent-Type: $type`r`nContent-Length: $($bytes.Length)`r`nCache-Control: no-cache`r`nConnection: close`r`n`r`n"
      $hb = [System.Text.Encoding]::ASCII.GetBytes($header)
      $stream.Write($hb, 0, $hb.Length)
      $stream.Write($bytes, 0, $bytes.Length)
    } else {
      $body = [System.Text.Encoding]::UTF8.GetBytes('404 Not Found')
      $header = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
      $hb = [System.Text.Encoding]::ASCII.GetBytes($header)
      $stream.Write($hb, 0, $hb.Length)
      $stream.Write($body, 0, $body.Length)
    }
    $stream.Flush()
    $client.Close()
  } catch {
    Write-Output "request error: $_"
  }
}
