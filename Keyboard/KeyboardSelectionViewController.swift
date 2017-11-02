//
//  KeyboardSelectionViewController.swift
//  TastyImitationKeyboard
//
//  Created by Simon Corston-Oliver on 2/01/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import UIKit

let kChooseTitle = "Choose one of the following keyboards"

class KeyboardSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @objc var tableView = UITableView()
    fileprivate var _keyboardDefinitions : [String] = []
    fileprivate var _langCode = "EN"

    required init()
    {
        super.init(nibName: nil, bundle: nil)
    }

    @objc convenience init(keyboardDefinitions: [String], langCode: String)
    {
        self.init()

        self._langCode = langCode

        self._keyboardDefinitions = keyboardDefinitions

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
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self._keyboardDefinitions.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return kChooseTitle
    }

    @objc func formatHeader(_ label: UILabel?) {
        let colorScheme = ColorScheme.ColorSchemeChooser(darkMode)
        label?.textColor = colorScheme.sectionLabelColor()
        label?.backgroundColor=colorScheme.sectionBackgroundColor()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = kChooseTitle

        formatHeader(label)

        return label
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let keyboardName = self._keyboardDefinitions[(indexPath as NSIndexPath).row]
        let colorScheme = ColorScheme.ColorSchemeChooser(darkMode)


        let cell = CheckedTableViewCell(layout: keyboardName, isDefault: keyboardName == getKeyboardLayoutNameForLanguageCode(self._langCode), colorScheme: colorScheme)

        return cell
    }

    // Tapping anywhere within the row that shows a keyboard layout is sufficient to change to that layout
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        setKeyboardLayoutNameForLanguageCode(self._langCode, layout: self._keyboardDefinitions[(indexPath as NSIndexPath).row])

        self.tableView.reloadData()
    }

}
