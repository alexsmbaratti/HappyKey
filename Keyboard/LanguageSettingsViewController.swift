//
//  LanguageSettingsViewController.swift
//  TastyImitationKeyboard
//
//  Created by Simon Corston-Oliver on 2/01/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import UIKit

let darkMode = false
let kUnknownLookupKey = "UNKNOWN"

class LanguageSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @objc var tableView = UITableView()
    fileprivate var _languageDefinitions : LanguageDefinitions? = nil
    fileprivate var _navController: CustomNavigationController? = nil

    required init()
    {
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(languageDefinitions: LanguageDefinitions, navController: CustomNavigationController?)
    {
        self.init()

        self._navController = nil

        self._languageDefinitions = languageDefinitions
        if self._languageDefinitions != nil {
            settingsList[LanguagesSection] = ("Languages", (self._languageDefinitions?.LangCodes())!)
        }

        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.frame = self.view.frame
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.view.addSubview(self.tableView)

        self.addConstraints()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("loading from nib not supported")
    }

    var settingsList: [(String, [String])] = [
        ("General Settings", [kAutoCapitalization, kPeriodShortcut, kKeyboardClicks]),
        ("Extra Settings", [kSmallLowercase]),
        ("Languages", ["English"])
    ]

    @objc var settingsNames: [String:String] {
        get {
            return [
                kAutoCapitalization: "Auto-Capitalization",
                kPeriodShortcut:  "“.” Shortcut",
                kKeyboardClicks: "Keyboard Clicks",
                kSmallLowercase: "Allow Lowercase Key Caps"
            ]
        }
    }

    @objc var settingsNotes: [String: String] {
        get {
            return [
                kSmallLowercase: "Changes your key caps to lowercase when Shift is off, making it easier to tell what mode you are in."
            ]
        }
    }

    @objc func addConstraints() {
        let views = ["tableView" : self.tableView]
        let metrics = ["pad" : 1]

        var allConstraints = [NSLayoutConstraint]()

        let topRowConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-pad-[tableView]-pad-|",
            options: [],
            metrics: metrics,
            views:views)
        allConstraints += topRowConstraints

        let verticalConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|[tableView]|",
            options: [],
            metrics: metrics,
            views:views)
        allConstraints += verticalConstraints

        NSLayoutConstraint.activate(allConstraints)
    }


    func numberOfSections(in tableView: UITableView) -> Int {
        return self.settingsList.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.settingsList[section].1.count
    }

    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        switch (indexPath as NSIndexPath).section {
        case 0:
            return 40
        case 1:
            return 75
        default:
            return 60
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.settingsList[section].0
    }

    @objc func formatHeader(_ label: UILabel?) {
        let colorScheme = ColorScheme.ColorSchemeChooser(darkMode)
        label?.textColor = colorScheme.sectionLabelColor()
        label?.backgroundColor=colorScheme.sectionBackgroundColor()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = self.settingsList[section].0.uppercased()

        formatHeader(label)

        return label
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let key = self.settingsList[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row]
        let colorScheme = ColorScheme.ColorSchemeChooser(darkMode)

        if (indexPath as NSIndexPath).section == LanguagesSection {
            let descriptiveName = LanguageDefinitions.Singleton().DescriptiveNameForLangCode(key)

            let cell = LanguageSettingsCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
            cell.initializeValues(descriptiveName, langCode: key, colorScheme: colorScheme, parentViewController: self)

            return cell
        }
        else if let explanatoryText = self.settingsNotes[key] {
            let cell = OptionWithDescription(style: UITableViewCellStyle.default, reuseIdentifier: nil)
            cell.initializeValues(key,
                label: self.settingsNames[key] ?? key,
                description: explanatoryText,
                colorScheme: colorScheme)

            return cell
        }
        else {
            let cell = DefaultSettingsTableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
            cell.initializeValues(key,
                label: self.settingsNames[key] ?? key,
                colorScheme: colorScheme)

            return cell
        }

    }

    @objc func switchToKeyboardSelectionViewController(_ recognizer: UITapGestureRecognizer, langCode: String) {

        let vc = KeyboardSelectionViewController(keyboardDefinitions: ["QWERTY", "AZERTY", "QWERTZ"], langCode: langCode)

        self._navController?.pushViewController(vc, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }

    @objc func updateAppearance() {
        //super.updateAppearance()

        let colorScheme = ColorScheme.ColorSchemeChooser(darkMode)

        // We have to explicitly redraw the section headings or they stay the same color if the user
        // flips between dark mode and light mode.
        self.tableView.reloadSections(IndexSet(integersIn: NSMakeRange(0, settingsList.count).toRange()!), with: UITableViewRowAnimation.automatic)

            for cell in self.tableView.visibleCells {
                (cell as? DefaultSettingsTableViewCell)?.applyColorScheme(colorScheme)
            }

    }

    @objc func toggleSetting(_ sender: UISwitch) {
        if let cell = sender.superview as? UITableViewCell {
            if let indexPath = self.tableView.indexPath(for: cell) {
                let descriptor = self.settingsList[(indexPath as NSIndexPath).section].1[(indexPath as NSIndexPath).row]
                let key = (indexPath as NSIndexPath).section == LanguagesSection ? LanguageDefinitions.Singleton().DescriptiveNameForLangCode(descriptor) : descriptor

                UserDefaults.standard.set(sender.isOn, forKey: key)
            }
        }
    }
}


// The settings form has a list of options. The cells in the list are implemented using a simple class hierarchy.
// DefaultSettingsTableViewCell     All options have at least a title and a switch to toggle them on and off.
// OptionWithDescription            Same as above but with added explanatory text
// LanguageSettingsCell             Options for enabling a language and choosing a keyboard layout for the language.

class DefaultSettingsTableViewCell: UITableViewCell {

    @objc var sw: UISwitch
    @objc var label: UILabel
    @objc var settingLookupKey: String

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.sw = UISwitch()
        self.label = UILabel(frame: CGRect.zero)
        self.settingLookupKey = kUnknownLookupKey

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.sw.translatesAutoresizingMaskIntoConstraints = false
        self.label.translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeValues(_ setting: String, label: String, colorScheme: ColorScheme)
    {
        self.settingLookupKey = setting
        self.sw.isOn = UserDefaults.standard.bool(forKey: setting)
        self.sw.addTarget(self, action: #selector(LanguageSettingsViewController.toggleSetting(_:)), for: UIControlEvents.valueChanged)

        self.label.text = label

        self.applyColorScheme(colorScheme)
        self.addConstraints()
    }

    @objc func toggleSetting(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: self.settingLookupKey)
    }

    func applyColorScheme(_ colorScheme: ColorScheme)
    {
        self.backgroundColor = colorScheme.cellBackgroundColor()
        self.label.textColor = colorScheme.cellLabelColor()

    }

    @objc func addConstraints() {
        self.addSubview(self.sw)
        self.addSubview(self.label)

        let views = ["label": self.label, "sw" : self.sw] as [String : Any]
        let metrics = ["pad" : 3.0]

        var allConstraints = [NSLayoutConstraint]()

        let topRowConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-pad-[label(>=150)]-[sw]-pad-|",
            options: [],
            metrics: metrics,
            views:views)
        allConstraints += topRowConstraints

        let verticalConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-pad-[label]",
            options: [],
            metrics: metrics,
            views:views)
        allConstraints += verticalConstraints

        let verticalConstraints2 = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-pad-[sw]",
            options: [],
            metrics: metrics,
            views:views)
        allConstraints += verticalConstraints2

        NSLayoutConstraint.activate(allConstraints)
    }

}

class OptionWithDescription : DefaultSettingsTableViewCell
{
    @objc var longLabel: UITextView

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.longLabel = MakeUITextView()

        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeValues(_ setting: String, label: String, description: String, colorScheme: ColorScheme)
    {
        self.longLabel.text = description
        super.initializeValues(setting, label: label, colorScheme: colorScheme)
    }

    override func applyColorScheme(_ colorScheme: ColorScheme)
    {
        super.applyColorScheme(colorScheme)

        self.longLabel.textColor = colorScheme.cellLongLabelColor()
    }

    override func addConstraints() {
        self.addSubview(self.sw)
        self.addSubview(self.label)
        self.addSubview(self.longLabel)

        self.addSubview(self.longLabel)

        let views = ["label": self.label, "longLabel": self.longLabel, "sw" : self.sw] as [String : Any]
        let metrics = ["pad" : 3.0, "widePad" : 16.0]

        var allConstraints = [NSLayoutConstraint]()

        let topRowConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-pad-[label(>=150)]-[sw]-pad-|",
            options: [],
            metrics: metrics,
            views:views)
        allConstraints += topRowConstraints

        let secondRowConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-widePad-[longLabel]-widePad-|",
            options: [],
            metrics: metrics,
            views:views)
        allConstraints += secondRowConstraints

        let verticalConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-pad-[label]-pad-[longLabel]-pad-|",
            options: [],
            metrics: metrics,
            views:views)
        allConstraints += verticalConstraints

        let verticalConstraints3 = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-pad-[sw]",
            options: [],
            metrics: metrics,
            views:views)
        allConstraints += verticalConstraints3

        NSLayoutConstraint.activate(allConstraints)
    }
}

class LanguageSettingsCell : DefaultSettingsTableViewCell
{
    @objc var kbdChanger: UITextView
    @objc var kbdName: UITextView
    @objc var parentViewController: LanguageSettingsViewController? = nil
    @objc var langCode : String = "HappyKey"

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.kbdName = MakeUITextView()
        self.kbdChanger = MakeUITextView()

        super.init(style: style, reuseIdentifier: reuseIdentifier)

    }

    func initializeValues(_ descriptiveName: String, langCode: String, colorScheme: ColorScheme, parentViewController: LanguageSettingsViewController)
    {
        self.langCode = langCode

        self.parentViewController = parentViewController

        self.sw.isOn = getLanguageCodeEnabled(langCode)
        self.sw.addTarget(self, action: #selector(LanguageSettingsViewController.toggleSetting(_:)), for: UIControlEvents.valueChanged)

        self.label.text = descriptiveName
        self.kbdName.text = getKeyboardLayoutNameForLanguageCode(self.langCode)

        self.kbdChanger.text = "Change..."
        self.kbdChanger.isUserInteractionEnabled = true

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(LanguageSettingsCell.goclick(_:)))
        recognizer.delegate = self

        self.kbdChanger.addGestureRecognizer(recognizer)

        self.applyColorScheme(colorScheme)
        self.addConstraints()
    }

    @objc func goclick(_ recognizer: UITapGestureRecognizer)
    {
        self.parentViewController?.switchToKeyboardSelectionViewController(recognizer, langCode: self.langCode)
    }

    override func toggleSetting(_ sender: UISwitch) {
        setLanguageCodeEnabled(self.langCode, value: sender.isOn)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func applyColorScheme(_ colorScheme: ColorScheme)
    {
        super.applyColorScheme(colorScheme)

        self.kbdChanger.textColor = colorScheme.cellKbdChangerColor()
    }

    override func addConstraints() {
        self.addSubview(self.sw)
        self.addSubview(self.label)
        self.addSubview(self.kbdName)

        self.addSubview(self.kbdChanger)

        let views = ["label": self.label, "kbdName": self.kbdName, "sw" : self.sw, "kbdChanger": self.kbdChanger] as [String : Any]
        let metrics = ["pad" : 3.0, "verticalpad": 1.0]

        var allConstraints = [NSLayoutConstraint]()

        let topRowConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-pad-[label(>=100)]-[sw]-pad-|",
            options: [],
            metrics: metrics,
            views:views)
        allConstraints += topRowConstraints


        let secondRowConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-pad-[kbdName(>=10)]-pad-[kbdChanger]",
            options: [],
            metrics: metrics,
            views:views)
        allConstraints += secondRowConstraints

        let verticalConstraints2 = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-pad-[label]-verticalpad-[kbdChanger]-pad-|",
            options: [],
            metrics: metrics,
            views:views)
        allConstraints += verticalConstraints2

        let verticalConstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-pad-[label]-verticalpad-[kbdName]-pad-|",
            options: [],
            metrics: metrics,
            views:views)
        allConstraints += verticalConstraints

        let verticalConstraints3 = NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-pad-[sw]",
            options: [],
            metrics: metrics,
            views:views)
        allConstraints += verticalConstraints3
        
        NSLayoutConstraint.activate(allConstraints)
    }
    
}

func MakeUITextView() -> UITextView
{
    let view = UITextView(frame: CGRect.zero)
    view.text = nil
    view.backgroundColor = UIColor.clear
    view.isScrollEnabled = false
    view.isSelectable = false
    view.translatesAutoresizingMaskIntoConstraints = false

    return view
}



