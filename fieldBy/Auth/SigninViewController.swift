//
//  SigninViewController.swift
//  fieldBy
//
//  Created by 박진서 on 2022/05/01.
//

import UIKit
import RxSwift
import RxCocoa
import NSObject_Rx

class SigninViewController: UIViewController {

    @IBOutlet weak var signinButton: UIButton!
    @IBOutlet weak var logoCenterYConstarint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        makeUI()
        animateView()
        bind()
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    private func makeUI() {
        
        self.navigationController?.navigationBar.isHidden = true
        signinButton.layer.cornerRadius = 13
//        signinButton.isHidden = true
    }
    
    private func animateView() {
        
//        logoCenterYConstarint.constant = -50
//
//        UIView.animate(withDuration: 0.5) {
//            self.view.layoutIfNeeded()
//        } completion: { _ in
//            self.signinButton.isHidden = false
//        }

    }
    
    private func bind() {
        
        signinButton.rx.tap
            .subscribe(onNext: { [unowned self] in
//                UITest()
                pushPhoneVC()
//                codeTest()
            })
            .disposed(by: rx.disposeBag)
    }
    
    
    private func pushPhoneVC() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "phoneVC") as? PhoneViewController else { return }
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    //UI Test
    
    private func UITest() {
        let vc = MainTabBarController()
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    private func codeTest() {


    }
}
