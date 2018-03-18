//
//  IndexBannerSubiew.swift
//  PageFlowView_Swift4
//
//  Created by lidongxi on 2018/3/13.
//  Copyright © 2018年 lidongxi. All rights reserved.
//

import UIKit

class IndexBannerSubiew: UIView {
    
    var didSelectCellBlock: ((Int,IndexBannerSubiew)->())?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(mainImageView)
        addSubview(coverView)
        
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(singleCellTapAction))
        addGestureRecognizer(singleTap)
    }
    
    @objc func singleCellTapAction(gesture : UIGestureRecognizer) {
        if didSelectCellBlock != nil {
            didSelectCellBlock!(tag,self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setSubviewsWithSuperViewBounds(superViewBounds: CGRect) {
        if superViewBounds.equalTo(mainImageView.frame) == true {
            return
        }
        mainImageView.frame = superViewBounds
        coverView.frame = superViewBounds
    }

    lazy var coverView: UIView = {
        let cover = UIView()
        cover.backgroundColor = UIColor.black
        return cover
    }()
    
    
    lazy var mainImageView: UIImageView = {
        let imageV = UIImageView.init()
        imageV.isUserInteractionEnabled = true
        return imageV
    }()

}
