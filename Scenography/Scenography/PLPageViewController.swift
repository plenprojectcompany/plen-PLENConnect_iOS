//
//  PLPageViewController.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/03.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation
import UIKit

// TODO: https://github.com/HighBay/PageMenu で置き換えたほうが良い

enum PLTabStyle {
    case None
    case InactiveFaded(fadedAlpha: CGFloat)
}

// MARK: -
class PLPageViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIToolbarDelegate, UIScrollViewDelegate {
    
    // MARK: - Variables
    
    // MARK: Protocols
    weak var datasource: PLPageViewControllerDataSource?
    weak var delegate: PLPageViewControllerDelegate?
    var pageViewScrollDelegate: UIScrollViewDelegate?
    
    // MARK: Pager
    private(set) var pageCount = 0
    private(set) var currentPageIndex = 0
    private(set) var pager: UIPageViewController!
    private var _pageViewControllers: [Int: UIViewController] = [:]
    
    // MARK: Tabs
    var tabWidth: CGFloat {return view.bounds.width / 3.0}
    var tabIndicatorHeight: CGFloat {return 2.0}
    var tabIndicatorColor: UIColor {return UIColor.lightGrayColor()}
    var tabMargin: CGFloat {return 0.0}
    var tabStyle: PLTabStyle {return .InactiveFaded(fadedAlpha: 0.566)}
    static private let _tabReuseIdentifier = "TabCell"
    
    // MARK: TabBar
    private(set) var tabBar: UICollectionView!
    
    // MARK: - UIViewController
    
    // MARK: Constructors
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    // MARK: Life cycle
    
    override func loadView() {
        super.loadView()
        
        loadPager()
        loadTabBar()
        
        layoutView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadData()
    }
    
    // MARK: - PageViewControllerDataSource
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        return indexForViewController(viewController).flatMap {viewControllerAtIndex($0 - 1)}
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        return indexForViewController(viewController).flatMap {viewControllerAtIndex($0 + 1)}
    }
    
    // MARK: - UIPageViewControllerDelegate
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if finished && completed, let index = pager.viewControllers?.first.flatMap(indexForViewController) {
            scrollToPageAtIndex(index, updatePage: false, animated: true)
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pageCount
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(
            PLPageViewController._tabReuseIdentifier,
            forIndexPath: indexPath)
        
        if let tabView = tabViewAtIndex(indexPath.row) {
            cell.contentView.subviews.forEach {$0.removeFromSuperview()}
            tabView.selected = (indexPath.row == currentPageIndex)
            cell.contentView.addSubview(tabView)
        }
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if currentPageIndex != indexPath.row {
            scrollToPageAtIndex(indexPath.row, updatePage: true, animated: true)
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(
            width: delegate?.widthForTabAtIndex?(indexPath.row) ?? tabWidth,
            height: tabBar.bounds.height)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return tabMargin
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return tabMargin
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: tabMargin / 2, bottom: 0, right: tabMargin / 2)
    }
    
    // MARK: - UIToolbarDelegate
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .Any
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        guard scrollView != tabBar else {return false}
        
        return pageViewScrollDelegate?.scrollViewShouldScrollToTop?(scrollView) ?? false
    }
    
    func scrollViewDidScrollToTop(scrollView: UIScrollView) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewDidScrollToTop?(scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewWillBeginDragging?(scrollView)
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewWillEndDragging?(scrollView,
            withVelocity: velocity,
            targetContentOffset: targetContentOffset)
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }
    
    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewWillBeginZooming?(scrollView, withView: view)
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewDidZoom?(scrollView)
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewDidEndZooming?(scrollView, withView: view, atScale: scale)
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        guard scrollView != tabBar else {return nil}
        
        return pageViewScrollDelegate?.viewForZoomingInScrollView?(scrollView)
    }
    
    // MARK: - Scroll programatically
    
    func scrollToPageAtIndex(index: Int, animated: Bool) {
        scrollToPageAtIndex(index, updatePage: true, animated: animated)
    }
    
    // MARK: - reload data
    
    func reloadData() {
        pageCount = datasource?.numberOfPagesForViewController(self) ?? 0
        _pageViewControllers.removeAll()
        tabBar.reloadData()
        
        pager.view.hidden = (pageCount == 0)
        if !pager.view.hidden {
            scrollToPageAtIndex(currentPageIndex, updatePage: true, animated: false)
        }
    }
    
    // MARK: - Private methods
    
    // MARK: Load
    
    private func loadPager() {
        pager = UIPageViewController(
            transitionStyle: UIPageViewControllerTransitionStyle.Scroll,
            navigationOrientation: UIPageViewControllerNavigationOrientation.Horizontal,
            options: nil)
        
        addChildViewController(pager)
        pager.didMoveToParentViewController(self)
        
        // TODO: このへんの処理の順番が謎
        let pagerScrollView = pager.view.subviews.first as! UIScrollView
        pageViewScrollDelegate = pagerScrollView.delegate
        pagerScrollView.scrollsToTop = false
        pagerScrollView.delegate = self
        
        pager.dataSource = self
        pager.delegate = self
    }
    
    private func loadTabBar() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .Horizontal
        tabBar = UICollectionView(frame: CGRect(), collectionViewLayout: flowLayout)
        
        tabBar.scrollEnabled = false
        tabBar.backgroundColor = UIColor.clearColor()
        tabBar.scrollsToTop = false
        tabBar.opaque = false
        tabBar.showsHorizontalScrollIndicator = false
        tabBar.showsVerticalScrollIndicator = false
        tabBar.registerClass(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: PLPageViewController._tabReuseIdentifier)
        
        tabBar.dataSource = self
        tabBar.delegate = self
    }
    
    private func layoutView() {
        view.addSubview(pager.view)
        UIViewUtil.constrain(by: view, subview: pager.view)
    }
    
    // MARK: Find
    
    private func indexForViewController(viewController: UIViewController) -> Int? {
        return _pageViewControllers.flatMap {$0.1 === viewController ? $0.0 : nil}.first
    }
    
    private func tabViewAtIndex(index: Int) -> PLTabView? {
        guard let tabViewContent: UIView = datasource?.tabViewForPageAtIndex(self, index: index) else {return nil}
        
        let width: CGFloat = delegate?.widthForTabAtIndex?(index) ?? tabWidth
        let tabView = PLTabView(
            frame: CGRect(x: 0, y: 0, width: width, height: tabBar.bounds.height),
            indicatorColor: tabIndicatorColor,
            indicatorHeight: tabIndicatorHeight,
            style: tabStyle)
        
        tabView.addSubview(tabViewContent)
        tabView.clipsToBounds = true
        tabViewContent.center = tabView.center
        return tabView
    }
    
    private func viewControllerAtIndex(index: Int) -> UIViewController? {
        guard 0 ..< pageCount ~= index else {return nil}
        if let vc = _pageViewControllers[index] {return vc}
        
        _pageViewControllers[index] = datasource?.viewControllerForPageAtIndex(self, index: index)
        return _pageViewControllers[index]
    }
    
    // MARK: Update
    
    private func scrollToPageAtIndex(index: Int, updatePage: Bool, animated: Bool) {
        assert(0 ..< pageCount ~= index)
        
        updateTabBar(index, animated: animated)
        
        if updatePage {
            updatePager(index, animated: animated)
        }
        
        currentPageIndex = index
        delegate?.didChangePageToIndex?(index)
    }
    
    private func updateTabBar(index: Int, animated: Bool) {
        assert(0 ..< pageCount ~= index)
        
        let currentIndexPath = NSIndexPath(forRow: currentPageIndex, inSection: 0)
        let currentTabCell = tabBar.cellForItemAtIndexPath(currentIndexPath)
        if let currentTabView = currentTabCell?.contentView.subviews.first as? PLTabView {
            currentTabView.selected = false
        }
        
        let newTabCell = tabBar.cellForItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0))
            ?? collectionView(tabBar, cellForItemAtIndexPath: NSIndexPath(forRow: index, inSection: 0))
        
        let newTabFrame = CGRect(
            x: newTabCell.frame.origin.x - (index == 0 ? tabMargin : tabMargin / 2.0),
            y: newTabCell.frame.origin.y,
            width: newTabCell.frame.size.width + tabMargin,
            height: newTabCell.frame.size.height)
        
        let newTabIsVisible = CGRectContainsRect(
            tabBar.frame,
            tabBar.convertRect(newTabCell.frame, toView: tabBar.superview))
        
        if !newTabIsVisible {
            tabBar.selectItemAtIndexPath(
                NSIndexPath(forRow: index, inSection: 0),
                animated: animated,
                scrollPosition: index > currentPageIndex ? .Right : .Left)
            tabBar.scrollRectToVisible(newTabFrame, animated: animated)
        }
        
        tabBar.scrollToItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0),
            atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally,
            animated: true)
        
        (newTabCell.contentView.subviews.first as! PLTabView).selected = true
    }
    
    private func updatePager(index: Int, animated: Bool) {
        assert(0 ..< pageCount ~= index)
        guard let vc = viewControllerAtIndex(index) else {return}
        
        pager.setViewControllers([vc],
            direction: index < currentPageIndex ? .Reverse : .Forward,
            animated: animated && index != currentPageIndex,
            completion: nil)
    }
}

// MARK: -
private class PLTabView: UIView {
    // MARK: - Variables
    
    var selected = false {
        didSet {
            switch style {
            case .InactiveFaded(let fadedAlpha):
                alpha = selected ? 1.0 : fadedAlpha
            default:
                break
            }
            setNeedsDisplay()
        }
    }
    var indicatorHeight = CGFloat(2.0)
    var indicatorColor = UIColor.lightGrayColor()
    var style = PLTabStyle.None
    
    // MARK: - Methods
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    init(frame: CGRect, indicatorColor: UIColor, indicatorHeight: CGFloat, style: PLTabStyle) {
        super.init(frame: frame)
        
        self.indicatorColor = indicatorColor
        self.indicatorHeight = indicatorHeight
        self.style = style
        
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = UIColor.clearColor()
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        guard selected else {return}
        
        let bezierPath = UIBezierPath()
        
        bezierPath.moveToPoint(CGPoint(x: 0, y: rect.height - indicatorHeight / 2))
        bezierPath.addLineToPoint(CGPoint(x: rect.width, y: rect.height - indicatorHeight / 2.0))
        bezierPath.lineWidth = indicatorHeight
        
        indicatorColor.setStroke()
        bezierPath.stroke()
    }
}

// MARK: - PLPageViewControllerDataSource
@objc
protocol PLPageViewControllerDataSource {
    /// Asks dataSource how many pages will there be.
    ///
    /// - parameter pageViewController: the PLPageViewController instance that's subject to
    ///
    /// - returns: the total number of pages
    func numberOfPagesForViewController(pageViewController: PLPageViewController) -> Int
    
    /// Asks dataSource to give a view to display as a tab item.
    ///
    /// - parameter pageViewController: the PLPageViewController instance that's subject to
    /// - parameter index: the index of the tab whose view is asked
    ///
    /// - returns: a UIView instance that will be shown as tab at the given index
    func tabViewForPageAtIndex(pageViewController: PLPageViewController, index: Int) -> UIView
    
    /// The content for any tab. Return a UIViewController instance and PLPageViewController will use its view to show as content.
    ///
    /// - parameter pageViewController: the PLPageViewController instance that's subject to
    /// - parameter index: the index of the content whose view is asked
    ///
    /// - returns: a UIViewController instance whose view will be shown as content
    func viewControllerForPageAtIndex(pageViewController: PLPageViewController, index: Int) -> UIViewController?
}

// MARK: - PLPageViewControllerDelegate
@objc
protocol PLPageViewControllerDelegate {
    /// Delegate objects can implement this method if want to be informed when a page changed.
    ///
    /// - parameter index: the index of the active page
    optional func willChangePageToIndex(index: Int, fromIndex from: Int)
    
    /// Delegate objects can implement this method if want to be informed when a page changed.
    ///
    /// - parameter index: the index of the active page
    optional func didChangePageToIndex(index: Int)
    
    /// Delegate objects can implement this method if tabs use dynamic width.
    ///
    /// - parameter index: the index of the tab
    /// - returns: the width for the tab at the given index
    optional func widthForTabAtIndex(index: Int) -> CGFloat
}