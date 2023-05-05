
注:本文是对`Objective-C`版本`NewPagedFlowView`的用Swift5重写

Objective-C版本,请移步https://github.com/PageGuo/NewPagedFlowView

**1.实现了什么功能**
* 页面滚动的方向分为横向和纵向
* 目的:实现类似于选择电影票的效果,并且实现无限/自动轮播
* 特点:1.无限轮播;2.自动轮播;3.电影票样式的层次感;4.非当前显示view具有缩放和透明的特效



**2.动画效果**

![vertical](https://github.com/dongxiexidu/PageFlowView_Swift4/blob/master/vertical.gif)
![horizontal](https://github.com/dongxiexidu/PageFlowView_Swift4/blob/master/horizontal.gif)


**3.功能介绍**

    /// 是否开启自动滚动,默认为开启
    public var isOpenAutoScroll = true
    /// 是否开启无限轮播,默认为开启
    var isCarousel = true
   
**更多属性设置,请看源代码**

**代理方法的使用**

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


**4.代码示例**

    // 模拟器原因,底部会有残影,真机测试没有
    let pageFlowView = PageFlowView.init(frame: CGRect.init(x: 0, y: 72, width: kScreenW, height: kScreenW*9/16))
    pageFlowView.backgroundColor = UIColor.white

    pageFlowView.delegate = self
    pageFlowView.dataSource = self
    pageFlowView.minimumPageAlpha = 0.1
    pageFlowView.isCarousel = true
    pageFlowView.orientation = .vertical
    pageFlowView.isOpenAutoScroll = true

    //初始化pageControl
    let pageControl = UIPageControl.init(frame: CGRect.init(x: 0, y: pageFlowView.bounds.height-32, width: kScreenW, height: 8))
    pageFlowView.pageControl = pageControl
    pageFlowView.addSubview(pageControl)
    pageFlowView.reloadData()
    view.addSubview(pageFlowView)
