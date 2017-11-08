Add-Type -AssemblyName System.Windows.Forms

#
# Function definition
#

# Calculate a, b (y = ax + b)

function getAB([Int]$x1, [Int]$y1, [Int]$x2, [Int]$y2){
	if ($x1 -eq $x2){
		$a = $null
		$b = $null
	}else{
		$a = ($y2 - $y1) / ($x2 - $x1)
		$b = (($x2 * $y1) - ($x1 * $y2)) / ($x2 - $x1)
	}
	return @($a, $b)
}

# Serach cross point

function getXY([Int]$x1, [Int]$y1, [Int]$x2, [Int]$y2, [Int]$x3, [Int]$y3, [Int]$x4, [Int]$y4){
	$ab = getAB $x1 $y1 $x2 $y2
	$a1 = $ab[0]
	$b1 = $ab[1]
	$ab = getAB $x3 $y3 $x4 $y4
	$a2 = $ab[0]
	$b2 = $ab[1]
	if ($a1 -eq $null -and $a2 -eq $null){
		$x = $null
		$y = $null
	}elseif ($a1 -eq $null){
		$x = $x1
		$y = ($a2 * $x1) + $b2
	}elseif ($a2 -eq $null){
		$x = $x2
		$y = ($a1 * $x2) + $b1
	}else{
		if ($a1 -eq $a2){
			$x = $null
			$y = $null
		}else{
			$x = ($b2 - $b1) / ($a1 - $a2)
			$y = (($a1 * $b2) - ($a2 * $b1)) / ($a1 - $a2)
		}
	}
	return @($x, $y)
}

# Judge cross or not

function isCross([Int]$x1, [Int]$y1, [Int]$x2, [Int]$y2, [Int]$x3, [Int]$y3, [Int]$x4, [Int]$y4){
	$ret = $false
	$xy = getXY $x1 $y1 $x2 $y2 $x3 $y3 $x4 $y4
	$x = $xy[0]
	$y = $xy[1]
	if ($x -ne $null -and $y -ne $null){
		if ($x1 -lt $x2){
			$wx1 = $x1
			$wx2 = $x2
		}else{
			$wx1 = $x2
			$wx2 = $x1
		}
		if ($y1 -lt $y2){
			$wy1 = $y1
			$wy2 = $y2
		}else{
			$wy1 = $y2
			$wy2 = $y1
		}
		if ($x3 -lt $x4){
			$wx3 = $x3
			$wx4 = $x4
		}else{
			$wx3 = $x4
			$wx4 = $x3
		}
		if ($y3 -lt $y4){
			$wy3 = $y3
			$wy4 = $y4
		}else{
			$wy3 = $y4
			$wy4 = $y3
		}
		if ($wx1 -le $x -and $x -le $wx2 -and $wy1 -le $y -and $y -le $wy2 -and
		    $wx3 -le $x -and $x -le $wx4 -and $wy3 -le $y -and $y -le $wy4){
			$ret = $true
		}
	}
	return $ret
}

# add information of point into $points

function addPoint([Int]$x, [Int]$y, [Object]$color, [Int]$width){
	$script:points_idx += 1
	$points[$script:points_idx] = @($x, $y, $color, $width)
}

# remove one line from $points

function removeLine([Int]$csx, [Int]$csy, [Int]$cex, [Int]$cey){
	foreach ($i in $points.keys | sort-object -descending){
		if ($points[$i][0] -eq -1 -and $points[$i][1] -eq -1){
			$sx = -1
			$sy = -1
			$ex = -1
			$ey = -1
			$start_idx = $i
		}else{
			if ($sx -eq -1 -and $sy -eq -1){
				$sx = $points[$i][0]
				$sy = $points[$i][1]
			}elseif ($ex -eq -1 -and $ey -eq -1){
				$ex = $points[$i][0]
				$ey = $points[$i][1]
				if (isCross $sx $sy $ex $ey $csx $csy $cex $cey){
					$points.remove($start_idx)
					$start_idx -= 1
					while ($points[$start_idx] -ne $null -and ($points[$start_idx][0] -ne -1 -or $points[$start_idx][1] -ne -1)){
						$points.remove($start_idx)
						$start_idx -= 1
					}
					break
				}
				$sx = $ex
				$sy = $ey
				$ex = -1
				$ey = -1
			}
		}
	}
}

# Redraw from $points

function redrawPen(){
	$pen_save = $pen
	foreach ($i in $points.keys | sort-object){
		if ($points[$i][0] -eq -1 -and $points[$i][1] -eq -1){
			$sx = -1
			$sy = -1
			$ex = -1
			$ey = -1
		}else{
			if ($sx -eq -1 -and $sy -eq -1){
				$sx = $points[$i][0]
				$sy = $points[$i][1]
			}elseif ($ex -eq -1 -and $ey -eq -1){
				$ex = $points[$i][0]
				$ey = $points[$i][1]
				$pen.color = $points[$i][2]
				$pen.width = $points[$i][3]
				$lgrpen.DrawLine($pen, $sx, $sy, $ex, $ey) # draw a line
				$sx = $ex
				$sy = $ey
				$ex = -1
				$ey = -1
			}
		}
	}
	$w.Refresh()
	$pen = $pen_save
}

#
# Take screenshot
#
#$pwidth = (gwmi win32_videocontroller).CurrentHorizontalResolution
$pwidth = (gwmi win32_videocontroller | out-string -stream | select-string CurrentHorizontalResolution | foreach{$_ -replace "^.*: *",""} | sort | select-object -Last 1)
#$pheight = (gwmi win32_videocontroller).CurrentVerticalResolution
$pheight = (gwmi win32_videocontroller | out-string -stream | select-string CurrentVerticalResolution | foreach{$_ -replace "^.*: *",""} | sort | select-object -Last 1)
$pimg = New-Object System.Drawing.Bitmap([Int]$pwidth, [Int]$pheight)
$pgr = [System.Drawing.Graphics]::FromImage($pimg)
$pgr.CopyFromScreen((New-Object System.Drawing.Point(0,0)), (New-Object System.Drawing.Point(0,0)), $pimg.Size)

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
# PictureBox for Pen
#
$pbpen = New-Object System.Windows.Forms.PictureBox
$pbpen.BackColor = [System.Drawing.Color]::Transparent

$lwidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$lheight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
$limgpen = New-Object System.Drawing.Bitmap($lwidth, $lheight)
$lgrpen = [System.Drawing.Graphics]::FromImage($limgpen)
$lgrpen.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

$pbpen.ClientSize = $limgpen.Size

$pbpen.Image = $limgpen
$pb.Controls.Add($pbpen)

#
# Menu
#

# Menu Window

$mw = New-Object System.Windows.Forms.Form
$mw.ClientSize = "360,90"
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
$btn_red.Size = "120,30"
$btn_red.Font = $font_bold
$btn_red.text = "RED"
$alpha = 255
$red = 255
$green = 0
$blue = 0
$btn_red.ForeColor = [System.Drawing.Color]::FromArgb($alpha, $red, $green, $blue)
$mw.Controls.Add($btn_red)

# GREEN Button

$btn_green = New-Object System.Windows.Forms.Button
$btn_green.Location = "120,0"
$btn_green.Size = "120,30"
$btn_green.Font = $font_regular
$btn_green.text = "GREEN"
$alpha = 255
$red = 0
$green = 255
$blue = 0
$btn_green.ForeColor = [System.Drawing.Color]::FromArgb($alpha, $red, $green, $blue)
$mw.Controls.Add($btn_green)

# Eraser Button

$btn_eraser = New-Object System.Windows.Forms.Button
$btn_eraser.Location = "240,0"
$btn_eraser.Size = "120,30"
$btn_eraser.Font = $font_regular
$btn_eraser.text = "ERASER"
$alpha = 255
$red = 0
$green = 0
$blue = 0
$btn_eraser.ForeColor = [System.Drawing.Color]::FromArgb($alpha, $red, $green, $blue)
$mw.Controls.Add($btn_eraser)

# PEN Width 5 Button

$btn_width5 = New-Object System.Windows.Forms.Button
$btn_width5.Location = "0,30"
$btn_width5.Size = "120,30"
$btn_width5.Font = $font_bold
$btn_width5.text = "Small"
$mw.Controls.Add($btn_width5)

# PEN Width 10 Button

$btn_width10 = New-Object System.Windows.Forms.Button
$btn_width10.Location = "120,30"
$btn_width10.Size = "120,30"
$btn_width10.Font = $font_regular
$btn_width10.text = "Middle"
$mw.Controls.Add($btn_width10)

# PEN Width 20 Button

$btn_width20 = New-Object System.Windows.Forms.Button
$btn_width20.Location = "240,30"
$btn_width20.Size = "120,30"
$btn_width20.Font = $font_regular
$btn_width20.text = "Large"
$mw.Controls.Add($btn_width20)

# Close Menu Button

$btn_mwclose = New-Object System.Windows.Forms.Button
$btn_mwclose.Location = "0,60"
$btn_mwclose.Size = "120,30"
$btn_mwclose.Font = $font_regular
$btn_mwclose.text = "Close Menu"
$mw.Controls.Add($btn_mwclose)

# Terminate pspen

$btn_terminate = New-Object System.Windows.Forms.Button
$btn_terminate.Location = "120,60"
$btn_terminate.Size = "120,30"
$btn_terminate.Font = $font_regular
$btn_terminate.text = "Exit Pen"
$mw.Controls.Add($btn_terminate)

# Screenshot

$btn_screenshot = New-Object System.Windows.Forms.Button
$btn_screenshot.Location = "240,60"
$btn_screenshot.Size = "120,30"
$btn_screenshot.Font = $font_regular
$btn_screenshot.text = "Save Image"
$mw.Controls.Add($btn_screenshot)

#
# Initialize work
#
$oldx = -1
$oldy = -1
$x = -1
$y = -1
$drag = $false
$eraser = $false

$points_idx = -1
$points = @{}
addPoint -1 -1 $null -1

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
		if ($script:eraser){
			$script:oldx = [System.Windows.Forms.Cursor]::Position.X
			$script:oldy = [System.Windows.Forms.Cursor]::Position.Y
		}else{
			$script:oldx = [System.Windows.Forms.Cursor]::Position.X
			$script:oldy = [System.Windows.Forms.Cursor]::Position.Y
			$script:x = $oldx
			$script:y = $oldy
			$lgrpen.FillPie($brush, ($script:x -($pen.width / 2)), ($script:y - ($pen.width / 2)), $pen.width, $pen.width, 0, 360) # draw a Pie
			$w.Refresh()
			addPoint $script:x $script:y $brush.color $pen.width
			$script:drag = $true
		}
	}
}
$pbpen.Add_MouseDown($mouse_down)

$mouse_up = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		if ($script:eraser){
			$script:x = [System.Windows.Forms.Cursor]::Position.X
			$script:y = [System.Windows.Forms.Cursor]::Position.Y
			removeLine $script:oldx $script:oldy $script:x $script:y
			$lgrpen.Clear($pbpen.BackColor)
			redrawPen
			$w.Refresh()
			$script:oldx = -1
			$script:oldy = -1
			$script:x = -1
			$script:y = -1
		}else{
			$script:oldx = -1
			$script:oldy = -1
			$script:x = -1
			$script:y = -1
			addPoint -1 -1 $null -1
			$script:drag = $false
		}
	}
}
$pbpen.Add_MouseUp($mouse_up)

#$double_click = {
#	if ($_.Button -eq "Right"){
#	}elseif ($_.Button -eq "Left"){
#	}
#}
#$pbpen.Add_DoubleClick($double_click)

$mouse_move = {
	if ($drag){
		if ($script:eraser){
		}else{
			$script:oldx = $x
			$script:oldy = $y
			$script:x = [System.Windows.Forms.Cursor]::Position.X
			$script:y = [System.Windows.Forms.Cursor]::Position.Y
			if ($script:oldx -ge 0 -and $script:oldy -ge 0){
				$lgrpen.DrawLine($pen, $script:oldx, $script:oldy, $script:x, $script:y) # draw a line
				$w.Refresh()
				addPoint $script:x $script:y $pen.color $pen.width
			}
		}
	}
}
$pbpen.Add_MouseMove($mouse_move)

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
		$btn_eraser.Font = $font_regular
		$script:eraser = $false
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
		$btn_eraser.Font = $font_regular
		$script:eraser = $false
	}
}
$btn_green.Add_Click($btn_green_click)

$btn_eraser_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$btn_red.Font = $font_regular
		$btn_green.Font = $font_regular
		$btn_eraser.Font = $font_bold
		$script:eraser = $true

#		$lgrpen.Clear($pbpen.BackColor)
#		$w.Refresh()
	}
}
$btn_eraser.Add_Click($btn_eraser_click)

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

$btn_screenshot_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$outfolder = [Environment]::GetFolderPath('Desktop')
		$outfile = "PsPen_" + (get-date -UFormat "%Y%m%d%H%M%S") + ".png"
		$outpath = $outfolder + "\" + $outfile
		$limgsave = $limg.clone()
		$lgrsave = [System.Drawing.Graphics]::FromImage($limgsave)
		$lgrsave.DrawImage($limgpen, 0, 0)
		$limgsave.Save($outpath)
		$limgsave.dispose()
		$lgrsave.dispose()
	}
}
$btn_screenshot.Add_Click($btn_screenshot_click)

#
# Set Cross cursor
#
$pbpen.Cursor = [System.Windows.Forms.Cursors]::Cross

#
# Start
#
$stat = $w.ShowDialog()

