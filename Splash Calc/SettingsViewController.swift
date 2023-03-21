//
//  SettingsViewController.swift
//  Splash Calc
//
//  Created by Haluk Isik on 7/6/15.
//  Copyright (c) 2015 Haluk Isik. All rights reserved.
//

import UIKit

@objc class SettingsViewController: UITableViewController
{
    let userDefaults = UserDefaults.standard
    let defaultGraphSettings: [Float] = [20.0, -10.0, 10.0, 0.2, 5.0]
    var userGraphSettings: [Float]!
    var lowerBound, upperBound: Float!
    
    var precision = Float() {
        didSet {
            let adjustedSliderValue = round(precision / 5) * 5 != 0 ? round(precision / 5) * 5 : 1
            let adjustedTextValue = round(precision / 5) * 5 != 0 ? round(precision / 5) * 5 : 1
            precisionSlider.setValue(adjustedSliderValue, animated: true)
            precisionLabel.text = "\(adjustedTextValue)"
            precision = adjustedSliderValue
        }
    }
    
    var startZoomLevel: Float = 0.0 {
        didSet {
            let adjustedSliderValue: Float = round(startZoomLevel)
            var adjustedTextValue: Float = 0.0
            if startZoomLevel > 0.5 {
                adjustedTextValue = round(startZoomLevel)
            } else {
                adjustedTextValue = -round((1 / round(startZoomLevel - 2)) * 100) / 100
            }
            
            startZoomLevelSlider.setValue(adjustedSliderValue, animated: false)
            startZoomLevelLabel.text = "\(adjustedTextValue)x"
            startZoomLevel = adjustedSliderValue
        }
    }
    
    var maxZoomLevel: Float = 0.0 {
        didSet {
            let adjustedSliderValue: Float = round(maxZoomLevel)
            var adjustedTextValue: Float = 0.0
            if maxZoomLevel > 0.5 {
                adjustedTextValue = round(maxZoomLevel)
            } else {
                adjustedTextValue = -round((1 / round(maxZoomLevel - 2)) * 100) / 100
            }
            
            maxZoomLevelSlider.setValue(adjustedSliderValue, animated: false)
            maxZoomLevelLabel.text = "\(adjustedTextValue)x"
            maxZoomLevel = adjustedSliderValue
        }
    }
    
    struct Settings {
        static let Graph = "defaultGraphSettings"
    }
    
    // MARK: - Precision Slider
    @IBOutlet weak var precisionSlider: UISlider!
    @IBOutlet weak var precisionLabel: UILabel!
    
    @IBAction func precisionValueChanged(_ sender: UISlider)
    {
        precision = sender.value
    }
    
    // MARK: - Plot Range Slider
    @IBOutlet weak var labelSlider: NMRangeSlider!
    var lowerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
    var upperLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 20))
    
    @IBOutlet weak var sliderContentView: UIView!

    func configureLabelSlider()
    {
        lowerLabel.textAlignment = .center
        upperLabel.textAlignment = .center
        
        lowerLabel.font = UIFont(name: "HelveticaNeue-Light", size: 14.0)
        upperLabel.font = UIFont(name: "HelveticaNeue-Light", size: 14.0)
        
        sliderContentView.addSubview(lowerLabel)
        sliderContentView.addSubview(upperLabel)
        
        labelSlider.minimumValue = -100
        labelSlider.maximumValue = 100
    
        labelSlider.lowerValue = -100
        labelSlider.upperValue = 100
    
        labelSlider.minimumRange = 20
    }
    
    func updateSliderLabels()
    {
    // You get get the center point of the slider handles and use this to arrange other subviews
    
        var lowerCenter = CGPoint()
        lowerCenter.x = labelSlider.lowerCenter.x + labelSlider.frame.origin.x
        lowerCenter.y = labelSlider.center.y - 30.0
        lowerLabel.center = lowerCenter
        lowerLabel.text = "\(Int(round(labelSlider.lowerValue)))"
        
        var upperCenter = CGPoint()
        upperCenter.x = labelSlider.upperCenter.x + labelSlider.frame.origin.x
        upperCenter.y = labelSlider.center.y - 30.0
        upperLabel.center = upperCenter
        upperLabel.text = "\(Int(round(labelSlider.upperValue)))"
        
        lowerBound = round(labelSlider.lowerValue)
        upperBound = round(labelSlider.upperValue)
        userGraphSettings[1] = lowerBound
        userGraphSettings[2] = upperBound
    }
    
    // Handle control value changed events just like a normal slider
    @IBAction func sliderValueChanged(_ sender: NMRangeSlider)
    {
        updateSliderLabels()
    }
    
    // MARK: - Start zoom level Slider
    @IBOutlet weak var startZoomLevelSlider: UISlider!
    @IBOutlet weak var startZoomLevelLabel: UILabel!
    
    @IBAction func startZoomLevelChanged(_ sender: UISlider)
    {
        if sender.value <= maxZoomLevel {
            startZoomLevel = sender.value
        } else {
            startZoomLevelSlider.setValue(maxZoomLevel, animated: false)
        }
    }
    
    
    // MARK: - Maximum zoom level Slider
    @IBOutlet weak var maxZoomLevelSlider: UISlider!
    @IBOutlet weak var maxZoomLevelLabel: UILabel!
    
    @IBAction func maxZoomLevelChanged(_ sender: UISlider)
    {
        if sender.value >= startZoomLevel {
            maxZoomLevel = sender.value
        } else {
            maxZoomLevelSlider.setValue(startZoomLevel, animated: false)
        }
    }
    
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Graph Settings"
        
        configureLabelSlider()
        readSettings()
        updateUI()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateSliderLabels()
    }

    override func viewWillLayoutSubviews() {
        updateSliderLabels()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        userGraphSettings = [precision, lowerBound, upperBound, startZoomLevel, maxZoomLevel]
        
        userDefaults.set(userGraphSettings, forKey: Settings.Graph)
        println("view will dissappear")
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return 1
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    {
//        if section == 1 {
//            let label = UILabel()
//            let footerView = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, 20))
//            footerView.addSubview(label)
//            
//            label.frame = footerView.frame
//            label.text = "Setting higher values for precision affects plot drawing performance."
//            label.numberOfLines = 0
//            label.font = UIFont.systemFontOfSize(14.0)
//            label.sizeToFit()
//            
//            return footerView
//            
//        }
        if section == 3 {
            let restoreButton = RestoreButton.instanceFromNib()
            
//            restoreButton.restore?.setTitle("Button Title 2", forState: UIControlState.Normal)
//            println("button view added")
            println(restoreButton.restore)
            restoreButton.restore?.addTarget(self, action: #selector(SettingsViewController.restoreAlert), for: UIControlEvents.touchUpInside)
            
            return restoreButton
            //return (NSBundle.mainBundle().loadNibNamed("RestoreButton", owner: self, options: nil).first as! UIView)
        }
//        println("f -> \(tableView.footerViewForSection(section))")
        return tableView.footerView(forSection: section)
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 3 {
            return CGFloat(100.0)
        }

//        println("h 1 -> \(tableView.footerViewForSection(section))")
//        println("h 2 -> \(tableView.footerViewForSection(section)?.frame.size.height)")
        
        return tableView.footerView(forSection: section)?.frame.size.height ?? 0.0
    }

    func restoreAlert()
    {
        var settingsAlert = UIAlertController(
            title: "Restore to defaults",
            message: "Are you sure you want to restore the settings to defaults?",
            preferredStyle: UIAlertControllerStyle.alert)
        
        settingsAlert.addAction(UIAlertAction(
            title: "Yes",
            style: .default,
            handler: { (action: UIAlertAction!) in
                println("restoring to defaults")
                self.restoreToDefaults()
                
        }))
        settingsAlert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { (action: UIAlertAction!) in
                println("canceled")
                
        }))
        
        present(settingsAlert, animated: true, completion: nil)
    }
    
    // MARK: - User Defaults
    
    func restoreToDefaults()
    {
        userDefaults.set(defaultGraphSettings, forKey: Settings.Graph)
        userGraphSettings = defaultGraphSettings

        updateUI()
        println("restored to defaults")
    }
    
    func readSettings()
    {
        if userDefaults.object(forKey: Settings.Graph) == nil {
            restoreToDefaults()
            return
        }
        userGraphSettings = userDefaults.object(forKey: Settings.Graph) as? [Float]
        
        if userGraphSettings == nil { restoreToDefaults() }
    }
    
    // MARK: - Update UI
    func updateUI()
    {
        precision = userGraphSettings[0]
        
        labelSlider.setLowerValue(userGraphSettings[1], upperValue: userGraphSettings[2], animated: false)
        updateSliderLabels()
        
        startZoomLevel = userGraphSettings[3]
        
        maxZoomLevel = userGraphSettings[4]
        
        let object: [Float] = userDefaults.object(forKey: Settings.Graph) as! [Float]
        
        println("object from updateUI = \(object)")
        
        println("userGraphSettings[3] = \(userGraphSettings[3])")
        println("startZoomLevel = \(startZoomLevel)")


    }
    
    // MARK: -
    
    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {

        println("prepare for segue")
        
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return UIInterfaceOrientation.portrait.rawValue
    }
    
    override var shouldAutorotate : Bool {
        return interfaceOrientation == UIInterfaceOrientation.portrait
    }
//    override func shouldAutorotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation) -> Bool {
//        return interfaceOrientation == UIInterfaceOrientation.Portrait
//    }

}
