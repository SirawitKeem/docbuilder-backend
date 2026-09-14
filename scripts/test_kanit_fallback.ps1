$ppt = New-Object -ComObject PowerPoint.Application
$pres = $ppt.Presentations.Add()
$slide = $pres.Slides.Add(1, 12)
$tb = $slide.Shapes.AddTextbox(1, 50, 50, 800, 100)
$tb.TextFrame.TextRange.Text = "ทดสอบ Kanit 2026 กลยุทธ์องค์กร DocBuilder"
$tb.TextFrame.TextRange.Font.Name = "Kanit"
$slide.Export("C:\Users\Keem\.gemini\antigravity\brain\3f255250-aae7-459e-82db-b987663452a8\test_kanit_fallback.png", "PNG", 1280, 720)
$pres.Close()
$ppt.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($ppt) | Out-Null
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
Write-Host "Kanit fallback exported!"
