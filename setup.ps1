# カレントディレクトリを取得
$currentDir = Get-Location

# scripts ディレクトリのパスを作成
$scriptsDir = Join-Path -Path $currentDir -ChildPath "scripts"

# 現在のPATHを取得
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)

# scripts ディレクトリがPATHに既に含まれていない場合に追加
if ($currentPath -notlike "*$scriptsDir*") {
    # 新しいPATHを作成
    $newPath = "$currentPath;$scriptsDir"
    
    # ユーザーの環境変数PATHを更新
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::User)

    # 現在のセッションに反映させる
    $env:PATH = $newPath

    Write-Output "Added '$scriptsDir' to PATH."
} else {
    Write-Output "'$scriptsDir' is already in PATH."
}
