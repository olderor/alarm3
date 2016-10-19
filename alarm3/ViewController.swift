//
//  ViewController.swift
//  alarm3
//
//  Created by olderor on 17.10.16.
//  Copyright © 2016 olderor. All rights reserved.
//

import UIKit

extension Int {
    func toTimeString() -> String {
        if self < 10 {
            return "0\(self)"
        }
        return "\(self)"
    }
}

func degree2radian(a:CGFloat)->CGFloat {
    let b = CGFloat(M_PI) * a/180
    return b
}

func circleCircumferencePoints(sides:Int,x:CGFloat,y:CGFloat,radius:CGFloat,adjustment:CGFloat=0)->[CGPoint] {
    let angle = degree2radian(a: 360/CGFloat(sides))
    let cx = x // x origin
    let cy = y // y origin
    let r  = radius // radius of circle
    var i = sides
    var points = [CGPoint]()
    while points.count <= sides {
        let xpo = cx - r * cos(angle * CGFloat(i)+degree2radian(a: adjustment))
        let ypo = cy - r * sin(angle * CGFloat(i)+degree2radian(a: adjustment))
        points.append(CGPoint(x: xpo, y: ypo))
        i -= 1;
    }
    return points
}

func secondMarkers(ctx:CGContext, x:CGFloat, y:CGFloat, radius:CGFloat, sides:Int, color:UIColor) {
    // retrieve points
    let points = circleCircumferencePoints(sides: sides,x: x,y: y,radius: radius)
    // create path
    let path = CGMutablePath()
    // determine length of marker as a fraction of the total radius
    var divider:CGFloat = 1/16
    var index = 0
    for p in points {
        if index % 5 == 0 {
            divider = 1/8
        }
        else {
            divider = 1/16
        }
        
        let xn = p.x + divider*(x-p.x)
        let yn = p.y + divider*(y-p.y)
        
        path.move(to: CGPoint(x: p.x, y: p.y))
        path.addLine(to: CGPoint(x: xn, y: yn))
        path.closeSubpath()
        ctx.addPath(path)
        
        index += 1
    }
    // set path color
    let cgcolor = color.cgColor
    ctx.setStrokeColor(cgcolor)
    ctx.setLineWidth(3.0)
    ctx.strokePath()
    
}

enum NumberOfNumerals:Int {
    case two = 2, four = 4, twelve = 12
}

func drawText(rect:CGRect, ctx:CGContext, x:CGFloat, y:CGFloat, radius:CGFloat, sides:NumberOfNumerals, color:UIColor) {
    
    ctx.translateBy(x: 0.0, y: rect.height)
    ctx.scaleBy(x: 1.0, y: -1.0)
    
    let inset:CGFloat = radius/3.5
    // An adjustment of 270 degrees to position numbers correctly
    let points = circleCircumferencePoints(sides: sides.rawValue,x: x,y: y,radius: radius-inset,adjustment:270)
    let path = CGMutablePath()
    // multiplier enables correcting numbering when fewer than 12 numbers are featured, e.g. 4 sides will display 12, 3, 6, 9
    let multiplier = 12/sides.rawValue
    
    var index = 0
    for p in points {
        if index > 0 {
            
            let aFont = UIFont.systemFont(ofSize: radius/5) //UIFont(name: "System", size: radius/5)
            // create a dictionary of attributes to be applied to the string
            let attr = [NSFontAttributeName:aFont,NSForegroundColorAttributeName:UIColor.black]
            // create the attributed string
            let str = String(index*multiplier)
            let text = CFAttributedStringCreate(nil, str as CFString!, attr as CFDictionary!)
            // create the line of text
            let line = CTLineCreateWithAttributedString(text!)
            // retrieve the bounds of the text
            let bounds = CTLineGetBoundsWithOptions(line, CTLineBoundsOptions.useOpticalBounds)
            // set the line width to stroke the text with
            ctx.setLineWidth(1.5)
            ctx.setTextDrawingMode(.stroke)
            // Set text position and draw the line into the graphics context, text length and height is adjusted for
            let xn = p.x - bounds.width/2
            let yn = p.y - bounds.midY
            ctx.textPosition = CGPoint(x: xn, y: yn)
            
            CTLineDraw(line, ctx)
        }
        index += 1
    }
    
}

class ClockView: UIView {
    
    
    override func draw(_ rect:CGRect)
        
    {
        
        // obtain context
        let ctx = UIGraphicsGetCurrentContext()
        
        // decide on radius
        let rad = rect.width/3.5
        
        let endAngle = CGFloat(2*M_PI)
        
        // add the circle to the context
        ctx?.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rad, startAngle: 0, endAngle: endAngle, clockwise: true)
        ctx?.setFillColor(UIColor.white.cgColor)
        
        ctx?.setStrokeColor(UIColor.black.cgColor)
        
        ctx?.setLineWidth(4.0)
        
        ctx?.drawPath(using: .fillStroke)
        
        
        
        secondMarkers(ctx: ctx!, x: rect.midX, y: rect.midY, radius: rad, sides: 60, color: UIColor.black)
        
        drawText(rect:rect, ctx: ctx!, x: rect.midX, y: rect.midY, radius: rad, sides: .twelve, color: UIColor.black)
        
        
        
        
    }
    
    
    
    
}

class ViewController: UIViewController, CAAnimationDelegate {
    
    
    
    
    func onHelpButtonTouchUpInside(_ sender: AnyObject) {
        
        let alert = UIAlertController(title: "Hint", message: "Drag clock hands to change the time. When done, press 'set alarm' button", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    

    func rotateLayer(currentLayer:CALayer,dur:CFTimeInterval){
        
        var angle = degree2radian(a: 360)
        
        var theAnimation = CABasicAnimation(keyPath:"transform.rotation.z")
        theAnimation.duration = dur
        // Make this view controller the delegate so it knows when the animation starts and ends
        theAnimation.delegate = self
        theAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        // Use fromValue and toValue
        theAnimation.fromValue = 0
        theAnimation.repeatCount = Float.infinity
        theAnimation.toValue = angle
        
        // Add the animation to the layer
        currentLayer.add(theAnimation, forKey:"rotate")
        
    }
    
    func ctime ()-> Time {
        if alarmTime != nil {
            return alarmTime
        }
        var t = time_t()
        time(&t)
        let x = localtime(&t) // returns UnsafeMutablePointer
        
        return Time(h:Int(x!.pointee.tm_hour),m:Int(x!.pointee.tm_min))
    }
    
    enum Arrow {
        case hour, minute
    }
    
    class Time {
        var h = 0
        var m = 0
        
        init(h: Int, m: Int) {
            self.h = h
            self.m = m
        }
        
        func toString() -> String {
            return h.toTimeString() + ":" + m.toTimeString()
        }
    }
    
    var arrowToDrag: Arrow! = nil
    var alarmTime: Time! = nil
    var newView = UIView()
    var timeLabel: UILabel! = nil
    var buttonsView: UIView! = nil
    
    func getTime(location: CGPoint) -> Time {
        var angle = Int(Double(atan(abs(location.x - newView.frame.midX)/abs(location.y - newView.frame.midY))) * 180.0 / M_PI)
        if location.y > newView.frame.midY {
            angle = 180 - angle
        }
        if location.x < newView.frame.midX {
            angle = 360 - angle
        }
        var minute = angle / 6
        if minute == 60 {
            minute = 0
        }
        return Time(h: minute / 5, m: minute)
    }
    
    
    func getPoint(location: CGPoint) -> CGPoint {

        let dxy = Double(sqrt(pow((location.y - newView.frame.midY), 2) + pow(location.x - newView.frame.midX, 2)))
        let d = arrowToDrag == .hour ? 20.0 : 30.0
        let newX = Double(location.x) * d / dxy
        let newY = Double(location.y) * d / dxy
        
        return CGPoint(x: newX, y: newY)
    }
    
    func  timeCoords(x:Double,y:Double,radius:Double,adjustment:Double=90)->(h:CGPoint, m:CGPoint) {
        let time = ctime()
        let cx = x // x origin
        let cy = y // y origin
        var r  = radius // radius of circle
        var points = [CGPoint]()
        var angle = 6.0 * M_PI / 180.0
        func newPoint (t:Double) {
            let xpo = cx - r * cos(angle * t + adjustment * M_PI / 180.0)
            let ypo = cy - r * sin(angle * t + adjustment * M_PI / 180.0)
            points.append(CGPoint(x: xpo, y: ypo))
        }
        // work out hours first
        var hours = time.h
        if hours > 12 {
            hours = hours-12
        }
        let hoursInSeconds = time.h*3600 + time.m*60
        newPoint(t: Double(hoursInSeconds)*5.0/3600.0)
        
        // work out minutes second
        r = radius * 1.5
        let minutesInSeconds = time.m*60
        newPoint(t: Double(minutesInSeconds)/60.0)
        return (h:points[0],m:points[1])
    }
    
    func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began {
            
            let location = gestureRecognizer.location(in: newView)
            
            let time = getTime(location: location)
            var d1 = (((time.h % 12) + 12 - (alarmTime.h % 12)) % 12) * 5
            d1 = min(d1, 60 - d1)
            var d2 = (time.m + 60 - alarmTime.m) % 60
            d2 = min(d2, 60 - d2)
            print("d: \(d1) - \(d2)")
            if min(d1, d2) > 5 {
                arrowToDrag = nil
                return
            }
            if d1 > d2 {
                arrowToDrag = .minute
            } else {
                arrowToDrag = .hour
            }
            
        }
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            
            if arrowToDrag == nil {
                return
            }
            
            let location = gestureRecognizer.location(in: newView)
            let time = getTime(location: location)
            if arrowToDrag == .hour {
                    if !(time.h == 0 && alarmTime.h % 12 == 11) && time.h < alarmTime.h % 12 || time.h == 11 && alarmTime.h % 12 == 0 {
                        alarmTime.h = (alarmTime.h - 1 + 24) % 24
                    } else if time.h > alarmTime.h % 12 || time.h == 0 && alarmTime.h % 12 == 11  {
                        alarmTime.h = (alarmTime.h + 1) % 24
                    }
            } else {
                if time.m == 59 && alarmTime.m < 30 {
                    alarmTime.h = (alarmTime.h - 1 + 24) % 24
                } else if (time.m == 60 || time.m == 0) && alarmTime.m > 30 {
                    alarmTime.h = (alarmTime.h + 1) % 24
                }
                alarmTime.m = time.m
            }
            let timec = timeCoords(x: Double(newView.frame.midX), y: Double(newView.frame.midY),radius: 50)
            drawArrows(h: timec.h, m: timec.m)
        }
    }
    
    
    func onDoneButtonTouchUpInside(_ sender: AnyObject?) {
        let alert = UIAlertController(title: "Done", message: "The alarm on \(alarmTime.toString()) was successfully set up", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func drawArrows(h: CGPoint, m: CGPoint) {
        let endAngle = CGFloat(2*M_PI)
        if newView.layer.sublayers != nil {
            for layer in newView.layer.sublayers! {
                layer.removeFromSuperlayer()
            }
        }
        
        if buttonsView == nil {
            buttonsView = UIView(frame: CGRect(x: 0, y: self.view.frame.height / 2 + self.view.frame.width / 2, width: self.view.frame.width, height:self.view.frame.height - self.view.frame.height / 2 - self.view.frame.width / 2))
            timeLabel = UILabel(frame: CGRect(x: 0, y: self.view.frame.height / 2 - self.view.frame.width / 2 - 41, width: self.view.frame.width, height: 41))
            timeLabel.textAlignment = .center
            timeLabel.font = timeLabel.font.withSize(40)
            
            let doneButton = UIButton(frame: CGRect(x:self.view.frame.width / 2 - 100 / 2, y: 10, width: 100, height: 21))
            doneButton.setTitle("set alarm", for: .normal)
            doneButton.titleLabel?.textAlignment = .center
            doneButton.addTarget(self, action: #selector(ViewController.onDoneButtonTouchUpInside(_:)), for: .touchUpInside)
            doneButton.setTitleColor(UIColor.init(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), for: .normal)
            
            let helpButton = UIButton(frame: CGRect(x: buttonsView.frame.width - 58, y: buttonsView.frame.height - 58, width: 50, height:50))
            helpButton.setImage(UIImage(named: "help.png"), for: .normal)
            helpButton.addTarget(self, action: #selector(ViewController.onHelpButtonTouchUpInside(_:)), for: .touchUpInside)
            
            buttonsView.addSubview(helpButton)
            buttonsView.addSubview(doneButton)
            self.view.addSubview(timeLabel)
        }
        newView.addSubview(buttonsView)
        timeLabel.text = ctime().toString()
        
        newView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        
        //newView.backgroundColor = UIColor.blue
        // Do any additional setup after loading the view, typically from a nib.
        // Hours
        let hourLayer = CAShapeLayer()
        hourLayer.frame = newView.frame
        let path = CGMutablePath()
        
        path.move(to: CGPoint(x: newView.frame.midX, y:newView.frame.midY))
        path.addLine(to: CGPoint(x: h.x, y: h.y))
        
        hourLayer.path = path
        hourLayer.lineWidth = 5
        hourLayer.lineCap = kCALineCapRound
        hourLayer.strokeColor = UIColor.red.cgColor
        
        
        hourLayer.rasterizationScale = UIScreen.main.scale;
        hourLayer.shouldRasterize = true
        
        newView.layer.addSublayer(hourLayer)
        // time it takes for hour hand to pass through 360 degress
        //rotateLayer(currentLayer: hourLayer,dur:43200)
        
        // Minutes
        let minuteLayer = CAShapeLayer()
        minuteLayer.frame = newView.frame
        let minutePath = CGMutablePath()
        
        minutePath.move(to: CGPoint(x: newView.frame.midX, y:newView.frame.midY))
        minutePath.addLine(to: CGPoint(x: m.x, y: m.y))
        
        minuteLayer.path = minutePath
        minuteLayer.lineWidth = 3
        minuteLayer.lineCap = kCALineCapRound
        minuteLayer.strokeColor = UIColor.red.cgColor
        
        minuteLayer.rasterizationScale = UIScreen.main.scale;
        minuteLayer.shouldRasterize = true
        
        newView.layer.addSublayer(minuteLayer)
        //rotateLayer(currentLayer: minuteLayer,dur: 3600)
        
        
        let centerPiece = CAShapeLayer()
        
        let circle = UIBezierPath(arcCenter: CGPoint(x:newView.frame.midX,y:newView.frame.midY), radius: 4.5, startAngle: 0, endAngle: endAngle, clockwise: true)
        
        centerPiece.path = circle.cgPath
        centerPiece.fillColor = UIColor.red.cgColor
        newView.layer.addSublayer(centerPiece)
        
        //newView.frame = CGRect(x: 0, y: self.view.frame.height / 2 - self.view.frame.width / 2, width: self.view.frame.width, height: self.view.frame.width)

    }
    
    
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        
        newView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        
        
        
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        newView.addGestureRecognizer(gestureRecognizer)
        
        
        alarmTime = ctime()
        self.view.addSubview(newView)
        let time = timeCoords(x: Double(newView.frame.midX), y: Double(newView.frame.midY), radius: 50)
        drawArrows(h: time.h, m: time.m)
    }


    func draw(view: UIView) {
        let time = timeCoords(x: Double(view.frame.midX), y: Double(view.frame.midY), radius: 50)
        let hourLayer = CAShapeLayer()
        hourLayer.frame = view.frame
        let path = CGMutablePath()
        path.move(to: CGPoint(x: view.frame.midX, y: view.frame.midY))
        path.addLine(to: CGPoint(x: time.h.x, y: time.h.y))
        hourLayer.path = path
        hourLayer.lineWidth = 4
        hourLayer.lineCap = kCALineCapRound
        hourLayer.strokeColor = UIColor.black.cgColor
    }
}

