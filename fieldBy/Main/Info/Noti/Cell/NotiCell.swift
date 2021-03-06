//
//  NotiCell.swift
//  fieldBy
//
//  Created by λ°μ§μ on 2022/05/27.
//

import Foundation
import UIKit

class NotiCell: UITableViewCell {
    static let reuseId = "notiCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    override func awakeFromNib() {
        mainImageView.layer.cornerRadius = 7
    }
    
    func bind(notiModel: NotiModel) {
        NotiManager.shared.read(notiUid: notiModel.uuid)
        timeLabel.text = notiModel.time.parseKoreanDateTime
        
        switch notiModel.type {
        case .instagram:
            titleLabel.text = "π μΈμ€νκ·Έλ¨ μ°λμ΄ μλ£λμμ΅λλ€!"
            contentLabel.text = "μνμλ νμ°¬μ μ°Έμ¬νμ€ μ μκ² λμμ΄μ! λ€μνκ³  νΈλ λν νμ°¬λ€μ νμΈνμΈμ."
            
        case .campaignApplied:
            if let url = notiModel.url {
                mainImageView.setImage(url: url)
            }
            
            if let title = notiModel.title {
                titleLabel.text = "ππ» '\(title)' μΊ νμΈ μ μ²­ μλ£!"
                contentLabel.text = "'\(title)'μΊ νμΈμ μ μ²­νμ¨μ΅λλ€!"

            }
            
        case .campaignSelected:
            if let url = notiModel.url {
                mainImageView.setImage(url: url)
            }
            
            if let title = notiModel.title {
                titleLabel.text = "π '\(title)' μΊ νμΈμ μ μ λμμ΅λλ€!"
                contentLabel.text = "'\(title)' μΊ νμΈμ μ μ λμμ΅λλ€. κ°μ΄λλΌμΈμ νμΈν΄λ³΄μΈμ!"

            }
        case .campaignOpened:
            if let url = notiModel.url {
                mainImageView.setImage(url: url)
            }
            
            if let title = notiModel.title {
                titleLabel.text = "ππ» '\(title)' μΊ νμΈ μ€ν!"
                contentLabel.text = "'\(title)'μΊ νμΈμ μ€ννμ΅λλ€. μ§κΈ νμΈν΄λ³΄μΈμ!"

            }
        case .itemDelivered:
            if let url = notiModel.url {
                mainImageView.setImage(url: url)
            }
            
            if let title = notiModel.title {
                titleLabel.text = "π '\(title)' μΊ νμΈ μν λ°μ‘!"
                contentLabel.text = "'\(title)' μΊ νμΈ μνμ΄ λ°μ‘λμμ΅λλ€!"
            }
        case .uploadFeed:
            if let url = notiModel.url {
                mainImageView.setImage(url: url)
            }
            
            if let title = notiModel.title {
                titleLabel.text = "π '\(title)' μΊ νμΈμ μλ‘λ ν΄μ£ΌμΈμ!"
                contentLabel.text = "'\(title)' μΊ νμΈ μλ‘λ κΈ°κ°μλλ€. κ°μ΄λμ λ§μΆ° μλ‘λ ν΄μ£ΌμΈμ!"
            }
        }
        
        deleteButton.rx.tap
            .subscribe(onNext: { 
                NotiManager.shared.delete(notiUid: notiModel.uuid)
            })
            .disposed(by: rx.disposeBag)
    }
}
