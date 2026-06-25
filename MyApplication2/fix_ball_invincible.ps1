$file = "C:\Users\ming\DevEcoStudioProjects\MyApplication2\entry\src\main\ets\common\GameManager.ets"
$lines = Get-Content $file
$newLines = @()
# Keep lines 0-787 (file lines 1-788, up to 'const ball = this.gameData.ball;')
for ($i = 0; $i -le 787; $i++) {
    $newLines += $lines[$i]
}
# Add updateBallInvincibility body
$newLines += "    if (ball.invincible) {"
$newLines += "      const currentTime = Date.now();"
$newLines += "      if (currentTime - ball.invincibleStartTime >= GameConfig.BALL_INVINCIBLE_DURATION) {"
$newLines += "        ball.invincible = false;"
$newLines += "      }"
$newLines += "    }"
$newLines += "  }"
# Skip lines 788-790 (blank lines and movePaddle comment header)
for ($i = 791; $i -lt $lines.Count; $i++) {
    $newLines += $lines[$i]
}
Set-Content -Path $file -Value $newLines -Encoding UTF8
Write-Host "Done. New file has $($newLines.Count) lines"
