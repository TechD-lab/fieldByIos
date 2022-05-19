//
//  DetailCampaignViewController.swift
//  fieldBy
//
//  Created by 박진서 on 2022/05/12.
//

import UIKit
import Kingfisher
import FirebaseStorage
import RxSwift

class DetailCampaignViewController: UIViewController {

    static let storyId = "detailcampaignVC"
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var mainImageView: UIImageView!
    
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var timeStickyContainer: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var isNewContainer: UIView!
    
    
    @IBOutlet weak var brandNameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    
    @IBOutlet weak var dateContainer: UIView!
    @IBOutlet weak var infoContainer: UIView!
    
    @IBOutlet weak var selectionDateLabel: UILabel!
    
    @IBOutlet weak var itemDateLabel: UILabel!
    
    @IBOutlet weak var betweenDateLabel: UILabel!
    
    @IBOutlet weak var leastFeedLabel: UILabel!
    @IBOutlet weak var maintainLabel: UILabel!
    
    @IBOutlet weak var uploadDateLabel: UILabel!
    
    @IBOutlet weak var shadowView: UIView!
    
    
    @IBOutlet weak var bottomTitleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var bottomView: UIView!
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet var viewModel: DetailCampaignViewModel!
    
    var campaignModel: CampaignModel!
    var image: UIImage!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        makeUI()
        bind()
    }
    

    private func makeUI() {
        indicator.isHidden = true
        timeStickyContainer.layer.cornerRadius = 14.5
        isNewContainer.layer.cornerRadius = 9.5
        dateContainer.layer.cornerRadius = 21
        dateContainer.addGrayShadow(color: .gray, opacity: 0.15, radius: 3)
        
        infoContainer.layer.cornerRadius = 21
        infoContainer.addGrayShadow(color: .gray, opacity: 0.15, radius: 3)
        mainScrollView.contentInsetAdjustmentBehavior = .never
        
        applyButton.layer.cornerRadius = 13
        
        bottomView.layer.cornerRadius = 21
        bottomView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        shadowView.layer.cornerRadius = 21
    }
    
    private func bind() {
        mainImageView.image = image

        brandNameLabel.text = campaignModel.brandName
        titleLabel.text = campaignModel.itemModel.name
        subTitleLabel.text = campaignModel.itemModel.description
        
        isNewContainer.isHidden = !campaignModel.isNew
        
        backButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.dismiss(animated: true)
            })
            .disposed(by: rx.disposeBag)
        
        Storage.storage().reference().child(campaignModel.mainImageUrl)
            .downloadURL { [unowned self] url, error in
                if let url = url {
                    mainImageView.kf.setImage(with: url)
                }
            }
        
        selectionDateLabel.text = campaignModel.selectionDate.parsedDate
        itemDateLabel.text = "~\(campaignModel.itemDate.parsedDate)"
        betweenDateLabel.text = "\(campaignModel.itemDate.parsedDate)~\(campaignModel.uploadDate.parsedDate)"
        uploadDateLabel.text = campaignModel.uploadDate.parsedDate
        
        
        bottomTitleLabel.text = campaignModel.itemModel.name
        priceLabel.text = getComma(price: campaignModel.itemModel.price)
        
        maintainLabel.text = "\(campaignModel.maintain)일"
        leastFeedLabel.text = "\(campaignModel.leastFeed)회"
        
        applyButton.rx.tap
            .throttle(.seconds(3), latest: false, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] in 
                viewModel.pushGuideVC()
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.pushGuideVC = { [unowned self] in
            indicator.isHidden = false
            indicator.startAnimating()
            CampaignManager.shared.guideImages(campaignModel: campaignModel)
                .subscribe(onNext: { [unowned self] guideImages in
                    
                    let vc = UIStoryboard(name: "GuideCampaign", bundle: nil).instantiateViewController(withIdentifier: "guidecampaignVC") as! GuideCampaignViewController
                    vc.campaignModel = campaignModel
                    vc.guideImages = guideImages
                    self.navigationController?.pushViewController(vc, animated: true)
                    indicator.stopAnimating()
                    indicator.isHidden = true
                })
                .disposed(by: rx.disposeBag)
        }
        
    }
    
    private func getComma(price : Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = NSLocale.current
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.usesGroupingSeparator = true
        return formatter.string(from: price as NSNumber) ?? ""
        
    }

    
}
