//
//  LanguageDefinition.swift
//  TastyImitationKeyboard
//
//  Created by Simon Corston-Oliver on 7/11/15.
//  Copyright © 2015 Apple. All rights reserved.
//

import Foundation

// The housekeeping information that defines a language:
// the name of the language, the characters required to type that language etc.
//
// Note that the language information says nothing about keyboard layout and doesn't attempt an exhaustive listing of the kbds that
// could be used to type the language. We can determine programmatically elsewhere if a kbd contains all the necessary chars.
open class LanguageDefinition {

    // The ISO 639-1 language code.
    // REVIEW What to do about languages that don't have an ISO 639-1 code?
    fileprivate let _langCode : String

    // Name of the language in English
    fileprivate let _englishName : String

    // Name of the language in that language's native script
    fileprivate let _nativeName : String

    // The name of the JSON keyboard definition file for the default keyboard for this language
    fileprivate let _defaultKbd : String

    // Special symbols that this language uses within what we will consider to be words e.g. apostrophe for English means
    // that we will consider "dog's" to be a single word. Similarly the middle dot in Catalan etc.
    fileprivate let _internalPunc : Set<String>

    init(langCode: String,
        englishName: String, nativeName: String, defaultKbd: String, internalPunc: [String])
    {
        self._langCode = langCode
        self._englishName = englishName
        self._nativeName = nativeName
        self._defaultKbd = defaultKbd
        self._internalPunc = Set<String>(internalPunc)
    }

    var LangCode : String {
        get {
            return self._langCode
        }
    }

    var EnglishName : String {
        get {
            return self._englishName
        }
    }

    var NativeName : String {
        get {
            return self._nativeName
        }
    }

    var DefaultKbdName : String {
        get {
            return self._defaultKbd
        }
    }

    var DescriptiveName : String {
        get {
            return EnglishName + "/" + NativeName
        }
    }

    var InternalPunc : Set<String> {
        get {
            return self._internalPunc
        }
    }

    // Default English language definition to be used in case of an emergency
    // e.g. failing to load language definitions from the JSON language definition file.
    class fileprivate func EnglishLanguageDefinition() -> LanguageDefinition {
        return LanguageDefinition(
            langCode: "HappyKey",
            englishName: "English",
            nativeName: "English",
            defaultKbd: "QWERTY",
            internalPunc: ["-", "'"])
    }
}

// Get and validate the current language to use
// If what we think is the current language has been disabled in settings, we need to pick another language
func CurrentLanguageCode() -> String {
    return UserDefaults.standard.string(forKey: kActiveLanguageCode) ?? EnabledLanguageCodes()[0]
}

func CurrentLanguageDefinition() -> LanguageDefinition? {
    return LanguageDefinitions.Singleton().langCodeToDefinition[CurrentLanguageCode()]
}


// Make the look up key for checking in user defaults which layout to use for language
func languageKeyboardLayout(_ langCode: String) -> String
{
    return langCode + "_layout"
}

func getKeyboardLayoutNameForLanguageCode(_ langCode: String) -> String
{
    let lookUpKey = languageKeyboardLayout(langCode)
    return UserDefaults.standard.string(forKey: lookUpKey) ?? LanguageDefinitions.Singleton().KeyboardFileForLanguageCode(langCode) ?? "QWERTY"
}

func setKeyboardLayoutNameForLanguageCode(_ langCode: String, layout: String)
{
    let lookUpKey = languageKeyboardLayout(langCode)
    return UserDefaults.standard.set(layout, forKey: lookUpKey)
}

func setDefaultKeyboardLayoutNameForLanguageCode(_ langCode: String, layout: String)
{
    let lookUpKey = languageKeyboardLayout(langCode)

    let currentValue = UserDefaults.standard.string(forKey: lookUpKey)
    if currentValue == nil {
        setKeyboardLayoutNameForLanguageCode(langCode, layout: layout)
    }
}

func langCodeEnabledKey (_ langCode: String) -> String
{
    return langCode + "_Enabled"
}

func getLanguageCodeEnabled(_ langCode: String) -> Bool
{
    return UserDefaults.standard.bool(forKey: langCodeEnabledKey(langCode))
}

func setLanguageCodeEnabled(_ langCode: String, value: Bool)
{
    return UserDefaults.standard.set(value, forKey: langCodeEnabledKey(langCode))
}

func EnabledLanguageCodes() -> [String]
{
    var enabledCodes: [String] = []

    let defs = LanguageDefinitions.Singleton().definitions

    for definition in defs {
        let key = definition.LangCode

        if getLanguageCodeEnabled(key) {
            enabledCodes.append(key)
        }
    }

    // Make sure at least one language is always enabled
    if enabledCodes.count == 0 {
        enabledCodes.append("HappyKey")
    }

    return enabledCodes
}


// class var not yet supported so make it global
private var _Singleton: LanguageDefinitions? = nil

// Define the set of languages currently supported
open class LanguageDefinitions {
    open var definitions : [LanguageDefinition] = []
    open var langCodeToDefinition: [String : LanguageDefinition] = [:]


    fileprivate func extractLanguageDefinitions(_ allDefinitions: NSDictionary)
    {
        if let languages = allDefinitions["languages"] as? NSArray {
            for language2 in languages {
                let language = language2 as! NSDictionary
              
                if let languageProperties = language["language"] as? NSDictionary {

                    if let englishName = languageProperties["englishName"] as? String,
                        let nativeName = languageProperties["nativeName"] as? String,
                        let defaultKbd = languageProperties["defaultKbd"] as? String,
                        let internalPunc = languageProperties["internalPunc"] as? [String],
                        let langCode = languageProperties["langCode"] as? String {

                            let definition = LanguageDefinition(
                                langCode: langCode,
                                englishName: englishName,
                                nativeName: nativeName,
                                defaultKbd: defaultKbd,
                                internalPunc: internalPunc)

                            self.definitions.append(definition)
                            self.langCodeToDefinition[definition.LangCode] = definition

                            setDefaultKeyboardLayoutNameForLanguageCode(definition.LangCode, layout: definition.DefaultKbdName)
                    }
                }

                
            }
        }
        else {
            makeDefaultLangDefinitions()
        }
    }

    // If we can't process the langauge definition file for some reason make sure we at least define English
    fileprivate func makeDefaultLangDefinitions()
    {
        definitions = [LanguageDefinition.EnglishLanguageDefinition()]
        langCodeToDefinition["HappyKey"] = definitions[0]
    }

    init(jsonFileName : String)
    {
        if let languageDefinitions = loadJSON("LanguageDefinitions") {

            self.extractLanguageDefinitions(languageDefinitions)
        }
        else {

            makeDefaultLangDefinitions()
        }
    }

    func LanguageNames() -> [String]
    {
        var names : [String] = []

        for languageDefinition in definitions {
            names.append(languageDefinition.DescriptiveName)
        }

        return names
    }

    func LangCodes() -> [String]
    {
        return langCodeToDefinition.keys.sorted()
    }

    func DescriptiveNameForLangCode(_ langCode: String) -> String {
        return self.langCodeToDefinition[langCode]?.DescriptiveName ?? "UNKNOWN"
    }

    func KeyboardFileForLanguageCode(_ langCode: String) -> String? {
        for lang in self.definitions {
            if lang.LangCode == langCode {
                return lang.DefaultKbdName
            }
        }

        return nil
    }

    class func Singleton() -> LanguageDefinitions {
        if _Singleton == nil {
            _Singleton = LanguageDefinitions(jsonFileName: "LanguageDefinitions")
        }

        return _Singleton!
    }
}
