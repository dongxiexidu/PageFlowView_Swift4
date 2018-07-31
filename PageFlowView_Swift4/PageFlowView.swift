//
//  PageFlowView.swift
//  PageFlowView_Swift4
//
//  Created by lidongxi on 2018/3/13.
//  Copyright © 2018年 lidongxi. All rights reserved.
//

import UIKit

enum PageFlowOrientation {
    case horizontal
    case vertical
}


protocol PageFlowViewDelegate : NSObjectProtocol{
    func sizeForPageInFlowView(flowView : PageFlowView) -> CGSize
    /// 滚动到了某一列
    func didScrollToPage(pageNumber : Int,inFlowView flowView : PageFlowView)
    
    /// 点击了第几个cell
    ///
    /// - Parameters:
    ///   - subView: 点击的控件
    ///   - subIndex: 点击控件的index
    func didSelectCell(subView : IndexBannerSubiew,subViewIndex subIndex : Int)
}

protocol PageFlowViewDataSource : NSObjectProtocol{
    /// 返回显示View的个数
    func numberOfPagesInFlowView(flowView : PageFlowView) -> Int
    
    /// 给某一列设置属性
    ///
    /// - Parameters:
    ///   - flowView: <#flowView description#>
    ///   - index: <#index description#>
    /// - Returns: <#return value description#>
    func cellForPageAtIndex(flowView : PageFlowView,atIndex index : Int) -> IndexBannerSubiew
}





class PageFlowView: UIView {
    
    /// 是否开启无限轮播,默认为开启
    var isCarousel = true
    public var orientation = PageFlowOrientation.horizontal
    
    public var needsReload = false
    /// 总页数
    public var pageCount : Int = 0
    public var cells = [AnyObject]()
    
    public var pageControl : UIPageControl?
    // 非当前页的透明比例
    public var minimumPageAlpha : CGFloat = 1.0
    
    
    public var _leftRightMargin : CGFloat = 20
    var leftRightMargin : CGFloat! {
        get {
            return _leftRightMargin
        }
        set{
            _leftRightMargin = newValue * CGFloat(0.5)
        }
    }
    public var _topBottomMargin : CGFloat = 30.0
    var topBottomMargin : CGFloat! {
        get {
            return _topBottomMargin
        }
        
        set{
            _topBottomMargin = newValue * CGFloat(0.5)
        }
    }
    
    
    
    /// 是否开启自动滚动,默认为开启
    public var isOpenAutoScroll = true
    /// 当前是第几页
    fileprivate var currentPageIndex : Int = 1
    /// 定时器
    public var timer : Timer?
    /// 自动切换视图的时间,默认是3.0
    public var autoTime : TimeInterval = 3.0
    /// 原始页数
    public var orginPageCount : Int = 0
    /// 一页的尺寸
    fileprivate var pageSize = CGSize.zero
    /// 计时器用到的页数
    fileprivate var page : Int = 0
    
    var visibleRange : NSRange = NSRange.init(location: 0, length: 0)
    
    var reusableCells = [IndexBannerSubiew]()
    var subviewClassName = "IndexBannerSubiew"
    
    weak var dataSource : PageFlowViewDataSource?
    weak var delegate : PageFlowViewDelegate?
    
    public lazy var scrollView: UIScrollView = {
        let scrollV = UIScrollView.init(frame: self.bounds)
        scrollV.scrollsToTop = false
        scrollV.delegate = self
        scrollV.isPagingEnabled = true
        scrollV.clipsToBounds = false
        scrollV.showsVerticalScrollIndicator = false
        scrollV.showsHorizontalScrollIndicator = false
        //        scrollV.backgroundColor = UIColor.blue
        return scrollV
    }()
    
    public func adjustCenterSubview() {
        if self.isOpenAutoScroll == true && self.orginPageCount > 0{
            scrollView.setContentOffset(CGPoint.init(x: self.pageSize.width*CGFloat(self.page), y: 0), animated: false)
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        leftRightMargin = 20
        topBottomMargin = 30
        self.clipsToBounds = true
        addSubview(scrollView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.point(inside: point, with: event) == true {
            return scrollView
        }
        return nil
    }
    
    
    func scrollToPage(pageNumber: Int) {
        if pageNumber < pageCount {
            stopTimer()
            if isCarousel == true {
                
                page = pageNumber + orginPageCount
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(startTimer), object: nil)
                perform(#selector(startTimer), with: nil, afterDelay: 0.5)
                
            }else{
                page = pageNumber
            }
            
            switch orientation {
                
            case .horizontal:
                scrollView.setContentOffset(CGPoint.init(x: pageSize.width * CGFloat(page), y: 0), animated: true)
            case .vertical:
                scrollView.setContentOffset(CGPoint.init(x: 0, y: pageSize.height * CGFloat(page)), animated: true)
            }
            
            setPagesAtContentOffset(offset: scrollView.contentOffset)
            refreshVisibleCellAppearance()
        }
    }
    
    func queueReusableCell(cell : IndexBannerSubiew) {
        reusableCells.append(cell)
    }
    
    func dequeueReusableCell() -> IndexBannerSubiew?{
        let cell = reusableCells.last
        if cell == nil {
            return nil
        }else{
            reusableCells.removeLast()
            return cell!
        }
    }
    
    
    func stopTimer() {
        if let myTimer = timer {
            myTimer.invalidate()
            timer = nil
        }
    }
    
    @objc func startTimer() {
        if orginPageCount > 1 && isOpenAutoScroll && isCarousel {
            
            // 异步调用 会有问题???
            DispatchQueue.main.async {
                
                let timers : Timer = Timer.scheduledTimer(timeInterval: self.autoTime, target: self, selector: #selector(self.autoNextPage(_:)), userInfo: nil, repeats: true)
                self.timer = timers
                RunLoop.main.add(timers, forMode: RunLoopMode.commonModes)
            }
        }
    }
    
    /// 自动轮播
    @objc func autoNextPage(_ timer: Timer) {
        
        self.timer = timer
        
        self.page = page+1
        switch orientation {
        case .horizontal:
            scrollView.setContentOffset(CGPoint.init(x: self.pageSize.width*CGFloat(self.page), y: 0), animated: true)
        case .vertical:
            scrollView.setContentOffset(CGPoint.init(x: 0, y: self.pageSize.height*CGFloat(self.page)), animated: true)
        }
    }
    
    func removeCellAtIndex(index: Int) {
        
        let cell = cells[index]
        if cell is NSNull {
            return
        }
        queueReusableCell(cell: cell as! IndexBannerSubiew)
        if cell.superview != nil {
            cell.removeFromSuperview()
        }
        cells[index] = NSNull.init()
    }
    
    
    func refreshVisibleCellAppearance() {
        if minimumPageAlpha == 1.0 && leftRightMargin == 0 && topBottomMargin == 0{
            return //无需更新
        }
        
        switch orientation {
        case .horizontal:
            let offsetX = scrollView.contentOffset.x
            for i in visibleRange.location..<visibleRange.location+visibleRange.length {
                let cell = cells[i] as! IndexBannerSubiew
                subviewClassName = NSStringFromClass(cell.classForCoder)
                let origin : CGFloat = cell.frame.origin.x
                let delta : CGFloat = fabs(origin-offsetX)
                
                //如果没有缩小效果的情况下的本该的Frame
                let originCellFrame : CGRect = CGRect.init(x: pageSize.width * CGFloat(i), y: 0, width: pageSize.width, height: pageSize.height)
                if delta < pageSize.width {
                    cell.coverView.alpha = (delta / pageSize.width) * minimumPageAlpha
                    let leftRightInset : CGFloat = self.leftRightMargin * delta / pageSize.width
                    let topBottomInset : CGFloat = self.topBottomMargin * delta / pageSize.width
                    cell.layer.transform = CATransform3DMakeScale((pageSize.width-leftRightInset*2)/pageSize.width, (pageSize.height-topBottomInset*2)/pageSize.height, 1.0)
                    cell.frame = UIEdgeInsetsInsetRect(originCellFrame, UIEdgeInsetsMake(topBottomInset, leftRightInset, topBottomInset, leftRightInset))
                    
                }else{
                    cell.coverView.alpha = minimumPageAlpha
                    cell.layer.transform = CATransform3DMakeScale((pageSize.width-leftRightMargin*2)/pageSize.width, (pageSize.height-topBottomMargin*2)/pageSize.height, 1.0)
                    cell.frame = UIEdgeInsetsInsetRect(originCellFrame, UIEdgeInsetsMake(topBottomMargin, leftRightMargin, topBottomMargin, leftRightMargin))
                }
                
            }
            
        case .vertical:
            let offsetY = scrollView.contentOffset.y
            
            for i in visibleRange.location..<visibleRange.location+visibleRange.length {
                let cell = cells[i] as! IndexBannerSubiew
                subviewClassName = NSStringFromClass(cell.classForCoder)
                let origin : CGFloat = cell.frame.origin.y
                let delta : CGFloat = fabs(origin-offsetY)
                
                //如果没有缩小效果的情况下的本该的Frame
                let originCellFrame : CGRect = CGRect.init(x: 0, y: pageSize.height * CGFloat(i), width: pageSize.width, height: pageSize.height)
                if delta < pageSize.height {
                    cell.coverView.alpha = (delta / pageSize.height) * minimumPageAlpha
                    let leftRightInset : CGFloat = leftRightMargin * delta / pageSize.height
                    let topBottomInset : CGFloat = topBottomMargin * delta / pageSize.height
                    cell.layer.transform = CATransform3DMakeScale((pageSize.width-leftRightInset*2)/pageSize.width, (pageSize.height-topBottomInset*2)/pageSize.height, 1.0)
                    cell.frame = UIEdgeInsetsInsetRect(originCellFrame, UIEdgeInsetsMake(topBottomInset, leftRightInset, topBottomInset, leftRightInset))
                    cell.mainImageView.frame = cell.bounds
                }else{
                    cell.coverView.alpha = minimumPageAlpha
                    cell.frame = UIEdgeInsetsInsetRect(originCellFrame, UIEdgeInsetsMake(topBottomMargin, leftRightMargin, topBottomMargin, leftRightMargin))
                    cell.mainImageView.frame = cell.bounds
                }
                
            }
            
            
        }
        
    }
    
    
    func setPageAtIndex(pageIndex: Int) {
        assert(pageIndex >= 0 && pageIndex < cells.count)
        
        var cell = cells[pageIndex] as? IndexBannerSubiew
        
        if cell == nil {
            cell = dataSource?.cellForPageAtIndex(flowView: self, atIndex: pageIndex % orginPageCount)
            
            assert(cell != nil, "datasource must not return nil")
            
            cells[pageIndex] = cell!
            
            cell?.tag = pageIndex % orginPageCount
            cell?.setSubviewsWithSuperViewBounds(superViewBounds: CGRect.init(x: 0, y: 0, width: pageSize.width, height: pageSize.height))
            
            cell?.didSelectCellBlock = {[weak self] tag,cell in
                self?.singleCellTapAction(selectTag: tag, withCell: cell)
            }
            
            switch orientation {
            case .horizontal:
                cell?.frame = CGRect.init(x: pageSize.width*CGFloat(pageIndex), y: 0, width: pageSize.width, height: pageSize.height)
            case .vertical:
                cell?.frame = CGRect.init(x: 0, y: pageSize.height*CGFloat(pageIndex), width: pageSize.width, height: pageSize.height)
            }
            
            if cell?.superview == nil {
                scrollView.addSubview(cell!)
            }
            
        }
        
    }
    
    
    func setPagesAtContentOffset(offset: CGPoint) {
        //计算visibleRange
        let startPoint = CGPoint.init(x: offset.x - scrollView.frame.origin.x, y: offset.y - scrollView.frame.origin.y)
        let endPoint = CGPoint.init(x: startPoint.x + bounds.width, y: startPoint.y + bounds.height)
        
        switch orientation {
        case .horizontal:
            var startIndex : Int = 0
            for i in 0..<cells.count {
                if pageSize.width * CGFloat(i + 1) > startPoint.x {
                    startIndex = i
                    break
                }
            }
            
            var endIndex = startIndex
            for i in startIndex..<cells.count {
                //如果都不超过则取最后一个
                if pageSize.width * CGFloat(i + 1) < endPoint.x && pageSize.width * CGFloat(i + 2) >= endPoint.x || i + 2 == cells.count {
                    
                    endIndex = i + 1
                    break
                }
            }
            //可见页分别向前向后扩展一个，提高效率
            startIndex = max(startIndex-1, 0)
            endIndex = min(endIndex+1, cells.count-1)
            visibleRange = NSRange.init(location: startIndex, length: endIndex-startIndex+1)
            
            for i in startIndex...endIndex {
                setPageAtIndex(pageIndex: i)
            }
            
            for i in 0..<startIndex {
                removeCellAtIndex(index: i)
            }
            
            for i in endIndex+1..<cells.count {
                removeCellAtIndex(index: i)
            }
            
        case .vertical:
            var startIndex : Int = 0
            for i in 0..<cells.count {
                if pageSize.height * CGFloat(i + 1) > startPoint.y {
                    startIndex = i
                    break
                }
            }
            
            var endIndex = startIndex
            for i in startIndex..<cells.count {
                //如果都不超过则取最后一个
                if (pageSize.height * CGFloat(i + 1) < endPoint.y && pageSize.height * CGFloat(i + 2) >= endPoint.y) || i + 2 == cells.count {
                    endIndex = i + 1//i+2 是以个数，所以其index需要减去1
                    break
                }
            }
            
            //可见页分别向前向后扩展一个，提高效率
            startIndex = max(startIndex-1, 0)
            endIndex = min(endIndex+1, cells.count-1)
            visibleRange = NSRange.init(location: startIndex, length: endIndex-startIndex+1)
            
            for i in startIndex...endIndex {
                setPageAtIndex(pageIndex: i)
            }
            
            for i in 0..<startIndex {
                removeCellAtIndex(index: i)
            }
            
            for i in endIndex+1..<cells.count {
                removeCellAtIndex(index: i)
            }
        }
        
        
    }
    
    
    
    func singleCellTapAction(selectTag : Int,withCell cell: IndexBannerSubiew) {
        if let myDelegate = delegate {
            myDelegate.didSelectCell(subView: cell, subViewIndex: selectTag)
        }
    }
    
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview != nil {
            stopTimer()
        }
    }
    
    deinit {
        scrollView.delegate = nil
    }
    
    
}



// MARK: PagedFlowView API
extension PageFlowView {
    
    func reloadData() {
        needsReload = true
        //移除所有self.scrollView的子控件
        for view in scrollView.subviews {
            if NSStringFromClass(view.classForCoder).elementsEqual(subviewClassName) || view is IndexBannerSubiew {
                
                view.removeFromSuperview()
            }
        }
        
        stopTimer()
        //如果需要重新加载数据，则需要清空相关数据全部重新加载
        if needsReload == true {
            if let data = dataSource {
                //原始页数
                orginPageCount = data.numberOfPagesInFlowView(flowView: self)
                if isCarousel == true {
                    pageCount = orginPageCount == 1 ? 1 : data.numberOfPagesInFlowView(flowView: self) * 3
                }else{
                    pageCount = orginPageCount == 1 ? 1 : data.numberOfPagesInFlowView(flowView: self)
                }
                
                //如果总页数为0，return
                if pageCount == 0 {
                    return
                }
                if let pageControl = pageControl {
                    pageControl.numberOfPages = orginPageCount
                }
                
            }
            //重置pageWidth
            pageSize = CGSize.init(width: bounds.width - 4 * leftRightMargin, height: (bounds.width - 4 * leftRightMargin) * 9 / 16)
            if let delegate = delegate {
                pageSize = delegate.sizeForPageInFlowView(flowView: self)
            }
            
            reusableCells.removeAll()
            visibleRange = NSRange.init(location: 0, length: 0)
            
            // 填充cells数组
            cells.removeAll()
            for _ in 0..<pageCount {
                cells.append(NSNull.init())
            }
            
            // 重置_scrollView的contentSize
            switch orientation {
            case .horizontal:
                scrollView.frame = CGRect.init(x: 0, y: 0, width: pageSize.width, height: pageSize.height)
                scrollView.contentSize = CGSize.init(width: pageSize.width * CGFloat(pageCount), height: 0)
                let theCenter = CGPoint.init(x: bounds.midX, y: bounds.midY)
                scrollView.center = theCenter
                
                if orginPageCount > 1 {
                    
                    if orginPageCount > 1 {
                        //滚到第二组
                        scrollView.setContentOffset(CGPoint.init(x: pageSize.width * CGFloat(orginPageCount), y: 0), animated: false)
                        page = orginPageCount
                        //启动自动轮播
                        startTimer()
                    }else{
                        //滚到开始
                        scrollView.setContentOffset(CGPoint.zero, animated: false)
                        page = orginPageCount
                    }
                }
                
            case .vertical:
                scrollView.frame = CGRect.init(x: 0, y: 0, width: pageSize.width, height: pageSize.height)
                scrollView.contentSize = CGSize.init(width: 0, height: pageSize.height * CGFloat(pageCount))
                let theCenter = CGPoint.init(x: bounds.midX, y: bounds.midY)
                scrollView.center = theCenter
                
                if orginPageCount > 1 {
                    
                    if isCarousel == true {
                        //滚到第二组
                        scrollView.setContentOffset(CGPoint.init(x: 0, y: pageSize.height * CGFloat(orginPageCount)), animated: false)
                        page = orginPageCount
                        //启动自动轮播
                        startTimer()
                    }else{
                        //滚到开始
                        scrollView.setContentOffset(CGPoint.zero, animated: false)
                        page = orginPageCount
                        
                    }
                }
            }
            needsReload = false
            
        }
        // 根据当前scrollView的offset设置cell
        setPagesAtContentOffset(offset: scrollView.contentOffset)
        
        //更新各个可见Cell的显示外貌
        refreshVisibleCellAppearance()
    }
    
    
}


extension PageFlowView : UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if orginPageCount == 0 {
            return
        }
        
        var pageIndex : Int = 0
        
        switch orientation {
        case .horizontal:
            
            pageIndex = Int(round(scrollView.contentOffset.x/pageSize.width).truncatingRemainder(dividingBy: CGFloat(orginPageCount)) )
        case .vertical:
            pageIndex = Int(round(scrollView.contentOffset.y/pageSize.height).truncatingRemainder(dividingBy: CGFloat(orginPageCount)) )
        }
        
        
        if isCarousel == true {
            if orginPageCount > 1 {
                
                switch orientation {
                case .horizontal:
                    
                    if scrollView.contentOffset.x / pageSize.width >= CGFloat(2 * orginPageCount) {
                        scrollView.setContentOffset(CGPoint.init(x: pageSize.width*CGFloat(orginPageCount), y: 0), animated: false)
                        page = orginPageCount
                    }
                    if scrollView.contentOffset.x / pageSize.width <= CGFloat(orginPageCount - 1) {
                        scrollView.setContentOffset(CGPoint.init(x: pageSize.width*CGFloat(2 * orginPageCount - 1), y: 0), animated: false)
                        page = 2 * orginPageCount
                    }
                case .vertical:
                    if scrollView.contentOffset.y / pageSize.height >= CGFloat(2 * orginPageCount) {
                        scrollView.setContentOffset(CGPoint.init(x: 0, y: pageSize.height*CGFloat(orginPageCount)), animated: false)
                        page = orginPageCount
                    }
                    if scrollView.contentOffset.y / pageSize.height <= CGFloat(orginPageCount - 1) {
                        scrollView.setContentOffset(CGPoint.init(x: 0, y: pageSize.height*CGFloat(2*orginPageCount - 1)), animated: false)
                        page = 2 * orginPageCount
                    }
                }
            }else{
                pageIndex = 0
            }
        }
        
        
        setPagesAtContentOffset(offset: scrollView.contentOffset)
        refreshVisibleCellAppearance()
        
        if let pageControl = pageControl {
            pageControl.currentPage = pageIndex
        }
        if let delegate = delegate,currentPageIndex != pageIndex && pageIndex >= 0 {
            delegate.didScrollToPage(pageNumber: pageIndex, inFlowView: self)
        }
        
        currentPageIndex = pageIndex
    }
    
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopTimer()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        startTimer()
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if self.orginPageCount > 1 && self.isOpenAutoScroll && self.isCarousel {
            
            switch orientation {
            case .horizontal:
                
                if page == Int(scrollView.contentOffset.x / pageSize.width) {
                    page = Int(scrollView.contentOffset.x / pageSize.width) + 1
                }else{
                    page = Int(scrollView.contentOffset.x / pageSize.width)
                }
                
            case .vertical:
                
                if page == Int(scrollView.contentOffset.y / pageSize.height) {
                    page = Int(scrollView.contentOffset.y / pageSize.height) + 1
                }else{
                    page = Int(scrollView.contentOffset.y / pageSize.height)
                }
                
            }
            
        }
    }
    
}
