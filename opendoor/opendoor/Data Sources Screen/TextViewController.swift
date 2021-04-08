//
//  TextViewController.swift
//  opendoor
//
//  Created by Aviel Gross on 4/7/21.
//

import UIKit

class TextViewController: UIViewController {

    @IBOutlet weak var textView: UITextView! {
        didSet {
            textView.backgroundColor = .systemGray6
            textView.layer.cornerRadius = 8
            textView.clipsToBounds = true

            textView.text = value
            textView.delegate = self
        }
    }

    var handleDismissWithValue: (String)->Void = { _ in }
    var value: String = ""

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        handleDismissWithValue(value)
    }
}

extension TextViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        value = textView.text
    }
}
