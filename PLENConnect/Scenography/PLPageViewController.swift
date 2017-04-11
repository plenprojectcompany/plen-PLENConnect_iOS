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
    case none
    case inactiveFaded(fadedAlpha: CGFloat)
}

// MARK: -
class PLPageViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIToolbarDelegate, UIScrollViewDelegate {
    
    // MARK: - Variables
    
    // MARK: Protocols
    weak var datasource: PLPageViewControllerDataSource?
    weak var delegate: PLPageViewControllerDelegate?
    var pageViewScrollDelegate: UIScrollViewDelegate?
    
    // MARK: Pager
    fileprivate(set) var pageCount = 0
    fileprivate(set) var currentPageIndex = 0
    fileprivate(set) var pager: UIPageViewController!
    fileprivate var _pageViewControllers: [Int: UIViewController] = [:]
    
    // MARK: Tabs
    var tabWidth: CGFloat {return view.bounds.width / 3.0}
    var tabIndicatorHeight: CGFloat {return 2.0}
    var tabIndicatorColor: UIColor {return UIColor.lightGray}
    var tabMargin: CGFloat {return 0.0}
    var tabStyle: PLTabStyle {return .inactiveFaded(fadedAlpha: 0.566)}
    static fileprivate let _tabReuseIdentifier = "TabCell"
    
    // MARK: TabBar
    fileprivate(set) var tabBar: UICollectionView!
    
    // MARK: - UIViewController
    
    // MARK: Constructors
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    // MARK: Life cycle
    
    override func loadView() {
        super.loadView()
        
        loadPager()
        loadTabBar()
        
        layoutView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadData()
    }
    
    // MARK: - PageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return indexForViewController(viewController).flatMap {viewControllerAtIndex($0 - 1)}
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return indexForViewController(viewController).flatMap {viewControllerAtIndex($0 + 1)}
    }
    
    // MARK: - UIPageViewControllerDelegate
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if finished && completed, let index = pager.viewControllers?.first.flatMap(indexForViewController) {
            scrollToPageAtIndex(index, updatePage: false, animated: true)
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pageCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PLPageViewController._tabReuseIdentifier,
            for: indexPath)
        
        if let tabView = tabViewAtIndex(indexPath.row) {
            cell.contentView.subviews.forEach {$0.removeFromSuperview()}
            tabView.selected = (indexPath.row == currentPageIndex)
            cell.contentView.addSubview(tabView)
        }
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if currentPageIndex != indexPath.row {
            scrollToPageAtIndex(indexPath.row, updatePage: true, animated: true)
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(
            width: delegate?.widthForTabAtIndex?(indexPath.row) ?? tabWidth,
            height: tabBar.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return tabMargin
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return tabMargin
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: tabMargin / 2, bottom: 0, right: tabMargin / 2)
    }
    
    // MARK: - UIToolbarDelegate
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .any
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        guard scrollView != tabBar else {return false}
        
        return pageViewScrollDelegate?.scrollViewShouldScrollToTop?(scrollView) ?? false
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewDidScrollToTop?(scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewWillBeginDragging?(scrollView)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewWillEndDragging?(scrollView,
            withVelocity: velocity,
            targetContentOffset: targetContentOffset)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewWillBeginZooming?(scrollView, with: view)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewDidZoom?(scrollView)
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard scrollView != tabBar else {return}
        
        pageViewScrollDelegate?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        guard scrollView != tabBar else {return nil}
        
        return pageViewScrollDelegate?.viewForZooming?(in: scrollView)
    }
    
    // MARK: - Scroll programatically
    
    func scrollToPageAtIndex(_ index: Int, animated: Bool) {
        scrollToPageAtIndex(index, updatePage: true, animated: animated)
    }
    
    // MARK: - reload data
    
    func reloadData() {
        pageCount = datasource?.numberOfPagesForViewController(self) ?? 0
        _pageViewControllers.removeAll()
        tabBar.reloadData()
        
        pager.view.isHidden = (pageCount == 0)
        if !pager.view.isHidden {
            scrollToPageAtIndex(currentPageIndex, updatePage: true, animated: false)
        }
    }
    
    // MARK: - Private methods
    
    // MARK: Load
    
    fileprivate func loadPager() {
        pager = UIPageViewController(
            transitionStyle: UIPageViewControllerTransitionStyle.scroll,
            navigationOrientation: UIPageViewControllerNavigationOrientation.horizontal,
            options: nil)
        
        addChildViewController(pager)
        pager.didMove(toParentViewController: self)
        
        // TODO: このへんの処理の順番が謎
        let pagerScrollView = pager.view.subviews.first as! UIScrollView
        pageViewScrollDelegate = pagerScrollView.delegate
        pagerScrollView.scrollsToTop = false
        pagerScrollView.delegate = self
        
        pager.dataSource = self
        pager.delegate = self
    }
    
    fileprivate func loadTabBar() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        tabBar = UICollectionView(frame: CGRect(), collectionViewLayout: flowLayout)
        
        tabBar.isScrollEnabled = false
        tabBar.backgroundColor = UIColor.clear
        tabBar.scrollsToTop = false
        tabBar.isOpaque = false
        tabBar.showsHorizontalScrollIndicator = false
        tabBar.showsVerticalScrollIndicator = false
        tabBar.register(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: PLPageViewController._tabReuseIdentifier)
        
        tabBar.dataSource = self
        tabBar.delegate = self
    }
    
    fileprivate func layoutView() {
        view.addSubview(pager.view)
        UIViewUtil.constrain(by: view, subview: pager.view)
    }
    
    // MARK: Find
    
    fileprivate func indexForViewController(_ viewController: UIViewController) -> Int? {
        return _pageViewControllers.flatMap {$0.1 === viewController ? $0.0 : nil}.first
    }
    
    fileprivate func tabViewAtIndex(_ index: Int) -> PLTabView? {
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
    
    fileprivate func viewControllerAtIndex(_ index: Int) -> UIViewController? {
        guard 0 ..< pageCount ~= index else {return nil}
        if let vc = _pageViewControllers[index] {return vc}
        
        _pageViewControllers[index] = datasource?.viewControllerForPageAtIndex(self, index: index)
        return _pageViewControllers[index]
    }
    
    // MARK: Update
    
    fileprivate func scrollToPageAtIndex(_ index: Int, updatePage: Bool, animated: Bool) {
        assert(0 ..< pageCount ~= index)
        
        updateTabBar(index, animated: animated)
        
        if updatePage {
            updatePager(index, animated: animated)
        }
        
        currentPageIndex = index
        delegate?.didChangePageToIndex?(index)
    }
    
    fileprivate func updateTabBar(_ index: Int, animated: Bool) {
        assert(0 ..< pageCount ~= index)
        
        let currentIndexPath = IndexPath(row: currentPageIndex, section: 0)
        let currentTabCell = tabBar.cellForItem(at: currentIndexPath)
        if let currentTabView = currentTabCell?.contentView.subviews.first as? PLTabView {
            currentTabView.selected = false
        }
        
        let newTabCell = tabBar.cellForItem(at: IndexPath(row: index, section: 0))
            ?? collectionView(tabBar, cellForItemAt: IndexPath(row: index, section: 0))
        
        let newTabFrame = CGRect(
            x: newTabCell.frame.origin.x - (index == 0 ? tabMargin : tabMargin / 2.0),
            y: newTabCell.frame.origin.y,
            width: newTabCell.frame.size.width + tabMargin,
            height: newTabCell.frame.size.height)
        
        let newTabIsVisible = tabBar.frame.contains(tabBar.convert(newTabCell.frame, to: tabBar.superview))
        
        if !newTabIsVisible {
            tabBar.selectItem(
                at: IndexPath(row: index, section: 0),
                animated: animated,
                scrollPosition: index > currentPageIndex ? .right : .left)
            tabBar.scrollRectToVisible(newTabFrame, animated: animated)
        }
        
        tabBar.scrollToItem(at: IndexPath(row: index, section: 0),
            at: UICollectionViewScrollPosition.centeredHorizontally,
            animated: true)
        
        (newTabCell.contentView.subviews.first as! PLTabView).selected = true
    }
    
    fileprivate func updatePager(_ index: Int, animated: Bool) {
        assert(0 ..< pageCount ~= index)
        guard let vc = viewControllerAtIndex(index) else {return}
        
        pager.setViewControllers([vc],
            direction: index < currentPageIndex ? .reverse : .forward,
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
            case .inactiveFaded(let fadedAlpha):
                alpha = selected ? 1.0 : fadedAlpha
            default:
                break
            }
            setNeedsDisplay()
        }
    }
    var indicatorHeight = CGFloat(2.0)
    var indicatorColor = UIColor.lightGray
    var style = PLTabStyle.none
    
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
        backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard selected else {return}
        
        let bezierPath = UIBezierPath()
        
        bezierPath.move(to: CGPoint(x: 0, y: rect.height - indicatorHeight / 2))
        bezierPath.addLine(to: CGPoint(x: rect.width, y: rect.height - indicatorHeight / 2.0))
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
    func numberOfPagesForViewController(_ pageViewController: PLPageViewController) -> Int
    
    /// Asks dataSource to give a view to display as a tab item.
    ///
    /// - parameter pageViewController: the PLPageViewController instance that's subject to
    /// - parameter index: the index of the tab whose view is asked
    ///
    /// - returns: a UIView instance that will be shown as tab at the given index
    func tabViewForPageAtIndex(_ pageViewController: PLPageViewController, index: Int) -> UIView
    
    /// The content for any tab. Return a UIViewController instance and PLPageViewController will use its view to show as content.
    ///
    /// - parameter pageViewController: the PLPageViewController instance that's subject to
    /// - parameter index: the index of the content whose view is asked
    ///
    /// - returns: a UIViewController instance whose view will be shown as content
    func viewControllerForPageAtIndex(_ pageViewController: PLPageViewController, index: Int) -> UIViewController?
}

// MARK: - PLPageViewControllerDelegate
@objc
protocol PLPageViewControllerDelegate {
    /// Delegate objects can implement this method if want to be informed when a page changed.
    ///
    /// - parameter index: the index of the active page
    @objc optional func willChangePageToIndex(_ index: Int, fromIndex from: Int)
    
    /// Delegate objects can implement this method if want to be informed when a page changed.
    ///
    /// - parameter index: the index of the active page
    @objc optional func didChangePageToIndex(_ index: Int)
    
    /// Delegate objects can implement this method if tabs use dynamic width.
    ///
    /// - parameter index: the index of the tab
    /// - returns: the width for the tab at the given index
    @objc optional func widthForTabAtIndex(_ index: Int) -> CGFloat
}
