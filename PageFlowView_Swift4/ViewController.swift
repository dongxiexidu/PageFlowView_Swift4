//
//  ViewController.swift
//  PageFlowView_Swift4
//
//  Created by lidongxi on 2018/3/13.
//  Copyright © 2018年 lidongxi. All rights reserved.
//

import UIKit

let kScreenW = UIScreen.main.bounds.size.width

class ViewController: UIViewController {
    
    var imageArray = [UIImage]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for i in 0..<5 {
            let name = String.init(format: "Yosemite%02d", i)
            let image = UIImage.init(named: name)
            imageArray.append(image!)
        }
        
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        let pageFlowView = PageFlowView.init(frame: CGRect.init(x: 0, y: 72, width: kScreenW, height: kScreenW*9/16))
        pageFlowView.delegate = self
        pageFlowView.dataSource = self
        pageFlowView.minimumPageAlpha = 0.1
        pageFlowView.isCarousel = true
        pageFlowView.orientation = .horizontal
        pageFlowView.isOpenAutoScroll = true
        
        //初始化pageControl
        let pageControl = UIPageControl.init(frame: CGRect.init(x: 0, y: pageFlowView.bounds.height-32, width: kScreenW, height: 8))
        pageFlowView.pageControl = pageControl
        pageFlowView.addSubview(pageControl)
        pageFlowView.reloadData()
        view.addSubview(pageFlowView)
        
    }
}

extension ViewController : PageFlowViewDelegate {
    func sizeForPageInFlowView(flowView: PageFlowView) -> CGSize {
        return CGSize.init(width: kScreenW-60, height: (kScreenW-60)*9/16)
    }
    
    func didScrollToPage(pageNumber: Int, inFlowView flowView: PageFlowView) {
        print("滚动到了第\(pageNumber)页")
    }
    
    func didSelectCell(subView: IndexBannerSubiew, subViewIndex subIndex: Int) {
         print("点击了第\(subIndex+1)页")
    }
    
    
    
}
extension ViewController : PageFlowViewDataSource {
    func numberOfPagesInFlowView(flowView: PageFlowView) -> Int {
        return imageArray.count
    }
    
    func cellForPageAtIndex(flowView: PageFlowView, atIndex index: Int) -> IndexBannerSubiew {
        var bannerView = flowView.dequeueReusableCell()
        
        if bannerView == nil {
            bannerView = IndexBannerSubiew.init(frame: CGRect.init(x: 0, y: 0, width: 320, height: 200))
            bannerView?.tag = index
            bannerView?.layer.cornerRadius = 4
            bannerView?.layer.masksToBounds = true
        }
        bannerView?.mainImageView.image = imageArray[index]
        
        return bannerView!
    }
    
    
}
