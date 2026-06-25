$file = "C:\Users\ming\DevEcoStudioProjects\MyApplication2\entry\src\main\ets\common\GameManager.ets"
$lines = Get-Content $file
$newLines = @()
for ($i = 0; $i -le 788; $i++) {
    $newLines += $lines[$i]
}
for ($i = 1003; $i -lt $lines.Count; $i++) {
    $newLines += $lines[$i]
}
Set-Content -Path $file -Value $newLines -Encoding UTF8
Write-Host "Done. New file has $($newLines.Count) lines"
