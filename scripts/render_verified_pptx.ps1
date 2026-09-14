
    $ppt = New-Object -ComObject PowerPoint.Application
    $pres = $ppt.Presentations.Open('C:\\Users\\Keem\\.gemini\\antigravity\\brain\\3f255250-aae7-459e-82db-b987663452a8\\phase_f_verified_presentation.pptx', $true, $false, $false)
    $slideIndex = 1
    foreach ($slide in $pres.Slides) {
      $imgName = "phase_f_slide" + $slideIndex + "_verified.png"
      $outImg = Join-Path 'C:\\Users\\Keem\\.gemini\\antigravity\\brain\\3f255250-aae7-459e-82db-b987663452a8' $imgName
      $slide.Export($outImg, "PNG", 1920, 1080)
      $pubImg = Join-Path 'c:\\Users\\Keem\\Desktop\\docbuilder\\public' $imgName
      Copy-Item $outImg $pubImg -Force
      Write-Host "Exported slide $slideIndex to $outImg"
      $slideIndex++
    }
    $pres.Close()
    $ppt.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ppt) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
  