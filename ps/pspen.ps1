Add-Type -AssemblyName System.Windows.Forms
#============================================================
# Function definition
#============================================================
#------------------------------------------------------------
# Calculate a, b (y = ax + b)
#------------------------------------------------------------
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
#------------------------------------------------------------
# Serach cross point
#------------------------------------------------------------
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
#------------------------------------------------------------
# Judge cross or not
#------------------------------------------------------------
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
#------------------------------------------------------------
# add information of point into $points
#------------------------------------------------------------
function addPoint([Int]$x, [Int]$y, [Object]$color, [Int]$width){
	$script:points_idx += 1
	$points[$script:points_idx] = @($x, $y, $color, $width)
}
#------------------------------------------------------------
# remove one line from $points
#------------------------------------------------------------
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
#------------------------------------------------------------
# Redraw from $points
#------------------------------------------------------------
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
#------------------------------------------------------------
# Get physical horizontal or vertical resolution
#------------------------------------------------------------
function getPhysicalResolution($hv){
	$ret = (gwmi win32_videocontroller | out-string -stream | select-string $hv | foreach{$_ -replace "^.*: *",""} | sort | select-object -Last 1)
	return $ret
}
#------------------------------------------------------------
# Get Bitmap and Graphics
#------------------------------------------------------------
function getImgAndGraph([Int]$width, [Int]$height){
	$img = New-Object System.Drawing.Bitmap($width, $height)
	$gr = [System.Drawing.Graphics]::FromImage($img)
	$gr.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
	return @($img, $gr)
}
#------------------------------------------------------------
# Get button
#------------------------------------------------------------
function getButton([Int]$x, [Int]$y, [Int]$width, [Int]$height, [Object]$font, [String]$text, [Int]$alpha, [Int]$red, [Int]$green, [Int]$blue){
	$btn = New-Object System.Windows.Forms.Button
	$btn.Location = "$x,$y"
	$btn.Size = "$width,$height"
	$btn.Font = $font
	$btn.text = $text
	$btn.ForeColor = [System.Drawing.Color]::FromArgb($alpha, $red, $green, $blue)
	return $btn
}
#============================================================
# Make Main window
#============================================================
#------------------------------------------------------------
# Take screenshot
#------------------------------------------------------------
$pwidth = getPhysicalResolution "CurrentHorizontalResolution"
$pheight = getPhysicalResolution "CurrentVerticalResolution"
$ret = getImgAndGraph $pwidth $pheight
$pimg = $ret[0]
$pgr = $ret[1]
$pgr.CopyFromScreen((New-Object System.Drawing.Point(0,0)), (New-Object System.Drawing.Point(0,0)), $pimg.Size)
#------------------------------------------------------------
# Show screenshot
#------------------------------------------------------------
$lwidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$lheight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
$w = New-Object System.Windows.Forms.Form
$w.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$pb = New-Object System.Windows.Forms.PictureBox
$ret = getImgAndGraph $lwidth $lheight
$limg = $ret[0]
$lgr = $ret[1]
$lgr.DrawImage($pimg, 0, 0, $lwidth, $lheight)
$w.ClientSize = $limg.Size
$pb.ClientSize = $limg.Size
$pb.Image = $limg
$w.Controls.Add($pb)
#------------------------------------------------------------
# PictureBox for Pen
#------------------------------------------------------------
$pbpen = New-Object System.Windows.Forms.PictureBox
$pbpen.BackColor = [System.Drawing.Color]::Transparent
$ret = getImgAndGraph $lwidth $lheight
$limgpen = $ret[0]
$lgrpen = $ret[1]
$pbpen.ClientSize = $limgpen.Size
$pbpen.Image = $limgpen
$pb.Controls.Add($pbpen)
#============================================================
# Make menu
#============================================================
#------------------------------------------------------------
# Size definition
#------------------------------------------------------------
$btn_width = 120
$btn_height = 30
$menu_width = $btn_width * 3
$menu_height = $btn_height * 3
#------------------------------------------------------------
# Font definition
#------------------------------------------------------------
$font_bold = New-Object System.Drawing.Font("Times New Roman",9,[System.Drawing.FontStyle]::Bold)
$font_regular = New-Object System.Drawing.Font("Times New Roman",9,[System.Drawing.FontStyle]::Regular)
#------------------------------------------------------------
# Menu Window
#------------------------------------------------------------
$mw = New-Object System.Windows.Forms.Form
$mw.ClientSize = "$menu_width,$menu_height"
$mw.startposition = "centerscreen"
$mw.text = "Menu"
$mw.MaximizeBox = $false
$mw.MinimizeBox = $false
$mw.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
#------------------------------------------------------------
# RED Button
#------------------------------------------------------------
#                    [Int]$x [Int]$y [Int]$width [Int]$height [Object]$font [String]$text [Int]$alpha [Int]$red [Int]$green [Int]$blue
$btn_red = getButton 0 0 $btn_width $btn_height $font_bold "RED" 255 255 0 0
$mw.Controls.Add($btn_red)
#------------------------------------------------------------
# GREEN Button
#------------------------------------------------------------
#                    [Int]$x [Int]$y [Int]$width [Int]$height [Object]$font [String]$text [Int]$alpha [Int]$red [Int]$green [Int]$blue
$btn_green = getButton ($btn_width * 1) 0 $btn_width $btn_height $font_regular "GREEN" 255 0 255 0
$mw.Controls.Add($btn_green)
#------------------------------------------------------------
# Eraser Button
#------------------------------------------------------------
#                    [Int]$x [Int]$y [Int]$width [Int]$height [Object]$font [String]$text [Int]$alpha [Int]$red [Int]$green [Int]$blue
$btn_eraser = getButton ($btn_width * 2) 0 $btn_width $btn_height $font_regular "ERASER" 255 0 0 0
$mw.Controls.Add($btn_eraser)
#------------------------------------------------------------
# PEN Width 5 Button
#------------------------------------------------------------
#                    [Int]$x [Int]$y [Int]$width [Int]$height [Object]$font [String]$text [Int]$alpha [Int]$red [Int]$green [Int]$blue
$btn_small = getButton 0 ($btn_height * 1) $btn_width $btn_height $font_bold "細ペン" 255 0 0 0
$mw.Controls.Add($btn_small)
#------------------------------------------------------------
# PEN Width 10 Button
#------------------------------------------------------------
#                    [Int]$x [Int]$y [Int]$width [Int]$height [Object]$font [String]$text [Int]$alpha [Int]$red [Int]$green [Int]$blue
$btn_middle = getButton ($btn_width * 1) ($btn_height * 1) $btn_width $btn_height $font_regular "中ペン" 255 0 0 0
$mw.Controls.Add($btn_middle)
#------------------------------------------------------------
# PEN Width 20 Button
#------------------------------------------------------------
#                    [Int]$x [Int]$y [Int]$width [Int]$height [Object]$font [String]$text [Int]$alpha [Int]$red [Int]$green [Int]$blue
$btn_large = getButton ($btn_width * 2) ($btn_height * 1) $btn_width $btn_height $font_regular "太ペン" 255 0 0 0
$mw.Controls.Add($btn_large)
#------------------------------------------------------------
# Close Menu Button
#------------------------------------------------------------
#                    [Int]$x [Int]$y [Int]$width [Int]$height [Object]$font [String]$text [Int]$alpha [Int]$red [Int]$green [Int]$blue
$btn_mwclose = getButton 0 ($btn_height * 2) $btn_width $btn_height $font_regular "メニューを閉じる" 255 0 0 0
$mw.Controls.Add($btn_mwclose)
#------------------------------------------------------------
# Terminate pspen Button
#------------------------------------------------------------
#                    [Int]$x [Int]$y [Int]$width [Int]$height [Object]$font [String]$text [Int]$alpha [Int]$red [Int]$green [Int]$blue
$btn_terminate = getButton ($btn_width * 1) ($btn_height * 2) $btn_width $btn_height $font_regular "ペンを終了する" 255 0 0 0
$mw.Controls.Add($btn_terminate)
#------------------------------------------------------------
# Screenshot Button
#------------------------------------------------------------
#                    [Int]$x [Int]$y [Int]$width [Int]$height [Object]$font [String]$text [Int]$alpha [Int]$red [Int]$green [Int]$blue
$btn_screenshot = getButton ($btn_width * 2) ($btn_height * 2) $btn_width $btn_height $font_regular "画像保存" 255 0 0 0
$mw.Controls.Add($btn_screenshot)
#============================================================
# Initialize work
#============================================================
$oldx = -1
$oldy = -1
$x = -1
$y = -1
$drag = $false
$eraser = $false

$points_idx = -1
$points = @{}
addPoint -1 -1 $null -1
#============================================================
# Initial Pen setting
#============================================================
$pen = new-object Drawing.Pen red
$pen.color = [System.Drawing.Color]::FromArgb(255, 255, 0, 0)
$pen.width = 5
$pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

$brush = [System.Drawing.Brushes]::black
$brush.color = [System.Drawing.Color]::FromArgb(255, 255, 0, 0)
#============================================================
# Main Event handler
#============================================================
$mouse_down = {
	if ($_.Button -eq "Right"){
		$stat = $mw.ShowDialog()
	}elseif ($_.Button -eq "Left"){
		$script:oldx = [System.Windows.Forms.Cursor]::Position.X
		$script:oldy = [System.Windows.Forms.Cursor]::Position.Y
		if ($script:eraser){
		}else{
			$script:x = $script:oldx
			$script:y = $script:oldy
			$lgrpen.FillPie($brush, ($script:x -($pen.width / 2)), ($script:y - ($pen.width / 2)), $pen.width, $pen.width, 0, 360) # draw a Pie
			$w.Refresh()
			addPoint $script:x $script:y $brush.color $pen.width
			$script:drag = $true
		}
	}
}
$pbpen.Add_MouseDown($mouse_down)
#------------------------------------------------------------
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
		}else{
			addPoint -1 -1 $null -1
			$script:drag = $false
		}
		$script:oldx = -1
		$script:oldy = -1
		$script:x = -1
		$script:y = -1
	}
}
$pbpen.Add_MouseUp($mouse_up)
#------------------------------------------------------------
$double_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
	}
}
$pbpen.Add_DoubleClick($double_click)
#------------------------------------------------------------
$mouse_move = {
	if ($drag){
		if ($script:eraser){
		}else{
			$script:oldx = $script:x
			$script:oldy = $script:y
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
#============================================================
# Menu Event handler
#============================================================
$btn_red_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$pen.color = [System.Drawing.Color]::FromArgb(255, 255, 0, 0)
		$brush.color = [System.Drawing.Color]::FromArgb(255, 255, 0, 0)
		$btn_red.Font = $font_bold
		$btn_green.Font = $font_regular
		$btn_eraser.Font = $font_regular
		$script:eraser = $false
	}
}
$btn_red.Add_Click($btn_red_click)
#------------------------------------------------------------
$btn_green_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$pen.color = [System.Drawing.Color]::FromArgb(255, 0, 255, 0)
		$brush.color = [System.Drawing.Color]::FromArgb(255, 0, 255, 0)
		$btn_red.Font = $font_regular
		$btn_green.Font = $font_bold
		$btn_eraser.Font = $font_regular
		$script:eraser = $false
	}
}
$btn_green.Add_Click($btn_green_click)
#------------------------------------------------------------
$btn_eraser_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$btn_red.Font = $font_regular
		$btn_green.Font = $font_regular
		$btn_eraser.Font = $font_bold
		$script:eraser = $true
	}
}
$btn_eraser.Add_Click($btn_eraser_click)
#------------------------------------------------------------
$btn_small_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$pen.width = 5
		$btn_small.Font = $font_bold
		$btn_middle.Font = $font_regular
		$btn_large.Font = $font_regular
	}
}
$btn_small.Add_Click($btn_small_click)
#------------------------------------------------------------
$btn_middle_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$pen.width = 10
		$btn_small.Font = $font_regular
		$btn_middle.Font = $font_bold
		$btn_large.Font = $font_regular
	}
}
$btn_middle.Add_Click($btn_middle_click)
#------------------------------------------------------------
$btn_large_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$pen.width = 20
		$btn_small.Font = $font_regular
		$btn_middle.Font = $font_regular
		$btn_large.Font = $font_bold
	}
}
$btn_large.Add_Click($btn_large_click)
#------------------------------------------------------------
$btn_mwclose_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$mw.Close()
	}
}
$btn_mwclose.Add_Click($btn_mwclose_click)
#------------------------------------------------------------
$btn_terminate_click = {
	if ($_.Button -eq "Right"){
	}elseif ($_.Button -eq "Left"){
		$mw.Close()
		$w.Close()
	}
}
$btn_terminate.Add_Click($btn_terminate_click)
#------------------------------------------------------------
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
#============================================================
# Set Cross cursor
#============================================================
$pbpen.Cursor = [System.Windows.Forms.Cursors]::Cross
#============================================================
# Go!
#============================================================
$stat = $w.ShowDialog()

