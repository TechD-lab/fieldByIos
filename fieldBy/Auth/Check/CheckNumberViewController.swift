//
//  CheckNumberViewController.swift
//  fieldBy
//
//  Created by 박진서 on 2022/05/02.
//

import UIKit
import PanModal
import RxSwift
import RxCocoa
import NSObject_Rx
import FirebaseAuth

class CheckNumberViewController: UIViewController {
    
    @IBOutlet weak var dragIndicator: UIView!
    @IBOutlet weak var requestButton: UIButton!
    @IBOutlet weak var codeView: UIView!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var codeContainer: UIView!
    
    @IBOutlet weak var reRequestButton: UIButton!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet var viewModel: CheckNumberViewModel!
    var topVC: PhoneViewController!
    var phoneNumber: String!
    
    private var timer: Timer?
    private var count = 0
    
    private var isKeyboardLoaded = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        makeUI()
        bind()
        
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [unowned self] timer in
            count += 1
            let min = (180-count)/60
            let sec = (180-count)%60
            
            timeLabel.text = "\(min):\(sec)"
            
            if count > 180 {
                timer.invalidate()
            }
        })

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let timer = timer {
            timer.invalidate()
        }
        
    }

    private func makeUI() {
        dragIndicator.layer.cornerRadius = 2.5
        requestButton.layer.cornerRadius = 13
        
        codeView.isHidden = true
        
        reRequestButton.layer.cornerRadius = 13
        reRequestButton.layer.borderWidth = 1
        reRequestButton.layer.borderColor = UIColor.fieldByGray.cgColor
        
        codeContainer.layer.cornerRadius = 13
        codeContainer.layer.borderWidth = 1
        codeContainer.layer.borderColor = UIColor.main.cgColor
        
        bottomView.isHidden = true
    }
    
    private func bind() {
        
        requestButton.rx.tap
            .throttle(.seconds(3), latest: false, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] in
                requestButton.isHidden = true
                codeView.isHidden = false
                codeTextField.becomeFirstResponder()

                viewModel.verify(phoneNumber: phoneNumber)
                    .subscribe {
                        print("complete")
                    } onError: { err in
                        print(err)
                    }
                    .disposed(by: rx.disposeBag)

            })
            .disposed(by: rx.disposeBag)
        
        reRequestButton.rx.tap
            .throttle(.seconds(3), latest: false, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] in
                requestButton.isHidden = true
                codeView.isHidden = false
                codeTextField.becomeFirstResponder()
                count = 0
                viewModel.verify(phoneNumber: phoneNumber)
                    .subscribe {
                        print("complete")
                    } onError: { err in
                        print(err)
                    }
                    .disposed(by: rx.disposeBag)
            })
            .disposed(by: rx.disposeBag)
        
        codeTextField.rx.text
            .orEmpty
            .bind(to: viewModel.codeSubject)
            .disposed(by: rx.disposeBag)
        
        viewModel.codeValidSubject
            .subscribe(onNext: { [unowned self] bool in
                if bool {
                    self.codeContainer.layer.borderWidth = 0
                    self.nextButton.backgroundColor = .main
                    nextButton.isEnabled = true
                } else {
                    self.codeContainer.layer.borderWidth = 1
                    self.nextButton.backgroundColor = UIColor(red: 147, green: 147, blue: 147)
                    nextButton.isEnabled = false
                }
            })
            .disposed(by: rx.disposeBag)
        
        nextButton.rx.tap
            .throttle(.seconds(3), latest: false, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] in
                
                //MARK: 지울 것

                viewModel.login(sixCode: codeTextField.text!, phoneNumber: phoneNumber)
                    .subscribe { [unowned self] in
                        let uuid = Auth.auth().currentUser!.uid
                        dismiss(animated: true) {
                            self.topVC.startWritingName(uuid: uuid)
                        }
                    } onError: { [unowned self] error in
                        presentAlert(message: "인증번호가 올바르지 않습니다.")
                    }
                    .disposed(by: rx.disposeBag)
                
            })
            .disposed(by: rx.disposeBag)
    }
    
    @objc func keyboardWillShowNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        let keyboardHeight = keyboardFrame.height
        
        self.bottomView.isHidden = false
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.bottomView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
        }
        isKeyboardLoaded = true
        panModalSetNeedsLayoutUpdate()
        panModalTransition(to: .longForm)
        
        
    }
    
    @objc func keyboardWillHideNotification(_ notification: Notification) {
        bottomView.isHidden = true
        bottomView.transform = .identity
        isKeyboardLoaded = false
        panModalSetNeedsLayoutUpdate()
        panModalTransition(to: .shortForm)
    }

}

extension CheckNumberViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var shortFormHeight: PanModalHeight {
        return .contentHeight(204)
    }
    
    var longFormHeight: PanModalHeight {
        return isKeyboardLoaded ? .contentHeight(260+CommmonView.shared.keyboardHeight) : .contentHeight(204)
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    var panModalBackgroundColor: UIColor {
        return UIColor.black.withAlphaComponent(0.6)
    }
}
