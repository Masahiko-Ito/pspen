#
#DEBUG $debug_imgpath = "screenshot.png"
#
Add-Type -AssemblyName System.Windows.Forms

#
# Take screenshot
#
$pwidth = (gwmi win32_videocontroller).CurrentHorizontalResolution
$pheight = (gwmi win32_videocontroller).CurrentVerticalResolution
$pimg = New-Object System.Drawing.Bitmap([Int]$pwidth, [Int]$pheight)
$pgr = [System.Drawing.Graphics]::FromImage($pimg)
$pgr.CopyFromScreen((New-Object System.Drawing.Point(0,0)), (New-Object System.Drawing.Point(0,0)), $pimg.Size)

#DEBUG $img.Save($debug_imgpath)

#
# Show screenshot
#
$w = New-Object System.Windows.Forms.Form
$w.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$pb = New-Object System.Windows.Forms.PictureBox

$lwidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$lheight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
$limg = New-Object System.Drawing.Bitmap($lwidth, $lheight)
$lgr = [System.Drawing.Graphics]::FromImage($limg)
$lgr.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$lgr.DrawImage($pimg, 0, 0, $lwidth, $lheight)

$w.ClientSize = $limg.Size
$pb.ClientSize = $limg.Size

$pb.Image = $limg
$w.Controls.Add($pb)

#
# Menu
#

# Menu Window

$mw = New-Object System.Windows.Forms.Form
$mw.Size = "240,130"
$mw.startposition = "centerscreen"
$mw.text = "Menu"
$mw.MaximizeBox = $false
$mw.MinimizeBox = $false
$mw.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle

# Font definition

$font_bold = New-Object System.Drawing.Font("Times New Roman",9,[System.Drawing.FontStyle]::Bold)
$font_regular = New-Object System.Drawing.Font("Times New Roman",9,[System.Drawing.FontStyle]::Regular)

# RED Button

$btn_red = New-Object System.Windows.Forms.Button
$btn_red.Location = "0,0"
$btn_red.Font = $font_bold
$btn_red.text = "Red"
$alpha = 255
$red = 255
$green = 0
$blue = 0
$btn_red.ForeColor = [System.Drawing.Color]::FromArgb($alpha, $red, $green, $blue)
$mw.Controls.Add($btn_red)

# GREEN Button

$btn_green = New-Object System.Windows.Forms.Button
$btn_green.Location = "100,0"
$btn_green.Font = $font_regular
$btn_green.text = "Green"
$alpha = 255
$red = 0
$green = 255
$blue = 0
$btn_green.ForeColor = [System.Drawing.Color]::FromArgb($alpha, $red, $green, $blue)
$mw.Controls.Add($btn_green)

# PEN Width 5 Button

$btn_width5 = New-Object System.Windows.Forms.Button
$btn_width5.Location = "0,30"
$btn_width5.Font = $font_bold
$btn_width5.text = "Small"
$mw.Controls.Add($btn_width5)

# PEN Width 10 Button

$btn_width10 = New-Object System.Windows.Forms.Button
$btn_width10.Location = "70,30"
$btn_width10.Font = $font_regular
$btn_width10.text = "Middle"
$mw.Controls.Add($btn_width10)

# PEN Width 20 Button

$btn_width20 = New-Object System.Windows.Forms.Button
$btn_width20.Location = "140,30"
$btn_width20.Font = $font_regular
$btn_width20.text = "Large"
$mw.Controls.Add($btn_width20)

# Close Menu Button

$btn_mwclose = New-Object System.Windows.Forms.Button
$btn_mwclose.Location = "0,60"
$btn_mwclose.Size = "90,30"
$btn_mwclose.text = "Close Menu"
$mw.Controls.Add($btn_mwclose)

# Terminate pspen

$btn_terminate = New-Object System.Windows.Forms.Button
$btn_terminate.Location = "100,60"
$btn_terminate.Size = "90,30"
$btn_terminate.text = "Terminate"
$mw.Controls.Add($btn_terminate)

#
# Initialize work
#
$oldx = -1
$oldy = -1
$x = -1
$y = -1
$drag = $false

#
# Initial Pen setting
#
$pen = new-object Drawing.Pen black
$alpha = 255
$red = 255
$green = 0
$blue = 0
$width = 5
$pen.color = [System.Drawing.Color]::FromArgb($alpha, $red, $green, $blue)
$pen.width = $width
$pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

$brush = [System.Drawing.Brushes]::black
$brush.color = [System.Drawing.Color]::FromArgb($alpha, $red, $green, $blue)

#
# Event handler
#
$mouse_down = {
	if ($_.Button -eq "Right"){
		$stat = $mw.ShowDialog()
	}elseif ($_.Button -eq "Left"){
		$global:oldx = [System.Windows.Forms.Cursor]::Position.X
		$global:oldy = [System.Windows.Forms.Cursor]::Position.Y
		$global:x = $oldx
		$global:y = $oldy
		$lgr.FillPie($brush, ($x -($pen.width / 2)), ($y - ($pen.width / 2)), $pen.width, $pen.width, 0, 360) # draw a Pie
		$w.Refresh()
		$global:drag = $true
	}
}
$pb.Add_MouseDown($mouse_down)

$mouse_up = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$global:oldx = -1
		$global:oldy = -1
		$global:x = -1
		$global:y = -1
		$global:drag = $false
	}
}
$pb.Add_MouseUp($mouse_up)

#$double_click = {
#	if ($_.Button -eq "Right"){
#	}elseif ($_.Button -eq "Left"){
#	}
#}
#$pb.Add_DoubleClick($double_click)

$mouse_move = {
	if ($drag){
		$global:oldx = $x
		$global:oldy = $y
		$global:x = [System.Windows.Forms.Cursor]::Position.X
		$global:y = [System.Windows.Forms.Cursor]::Position.Y
		if ($oldx -ge 0 -and $oldy -ge 0){
			$lgr.DrawLine($pen, $oldx, $oldy, $x, $y) # draw a line
			$w.Refresh()
		}
	}
}
$pb.Add_MouseMove($mouse_move)

#
# Menu Event handler
#
$btn_red_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$alpha = 255
		$red = 255
		$green = 0
		$blue = 0
		$pen.color = [System.Drawing.Color]::FromArgb($alpha, $red, $green, $blue)
		$brush.color = [System.Drawing.Color]::FromArgb($alpha, $red, $green, $blue)
		$btn_red.Font = $font_bold
		$btn_green.Font = $font_regular
	}
}
$btn_red.Add_Click($btn_red_click)

$btn_green_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$alpha = 255
		$red = 0
		$green = 255
		$blue = 0
		$pen.color = [System.Drawing.Color]::FromArgb($alpha, $red, $green, $blue)
		$brush.color = [System.Drawing.Color]::FromArgb($alpha, $red, $green, $blue)
		$btn_red.Font = $font_regular
		$btn_green.Font = $font_bold
	}
}
$btn_green.Add_Click($btn_green_click)

$btn_width5_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$width = 5
		$pen.width = $width
		$btn_width5.Font = $font_bold
		$btn_width10.Font = $font_regular
		$btn_width20.Font = $font_regular
	}
}
$btn_width5.Add_Click($btn_width5_click)

$btn_width10_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$width = 10
		$pen.width = $width
		$btn_width5.Font = $font_regular
		$btn_width10.Font = $font_bold
		$btn_width20.Font = $font_regular
	}
}
$btn_width10.Add_Click($btn_width10_click)

$btn_width20_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$width = 20
		$pen.width = $width
		$btn_width5.Font = $font_regular
		$btn_width10.Font = $font_regular
		$btn_width20.Font = $font_bold
	}
}
$btn_width20.Add_Click($btn_width20_click)

$btn_mwclose_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$mw.Close()
	}
}
$btn_mwclose.Add_Click($btn_mwclose_click)

$btn_terminate_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$mw.Close()
		$w.Close()
	}
}
$btn_terminate.Add_Click($btn_terminate_click)

#
# Start
#
$stat = $w.ShowDialog()
