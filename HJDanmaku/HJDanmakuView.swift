//
//  HJDanmakuView.swift
//  Pods
//
//  Created by haijiao on 2017/8/2.
//
//

import UIKit

func onMainThreadAsync(closure: @escaping () -> ()) {
    if Thread.isMainThread {
        closure()
    } else {
        DispatchQueue.main.async(execute: closure)
    }
}

func onGlobalThreadAsync(closure: @escaping () -> ()) {
    DispatchQueue.global().async {
        closure()
    }
}

public struct HJDanmakuTime {
    
    public var time: Float
    public var interval: Float
    
    public func MaxTime() -> Float {
        return time + interval;
    }
    
}

public struct HJDanmakuAgent {
    
    let danmakuModel: HJDanmakuModel
    var danmakuCell: HJDanmakuCell?
    
    var force: Bool = false
    
    var toleranceCount = 4
    var remainingTime: Float = 5.0
    
    var px: Float = 0
    var py: Float = 0
    var size: CGSize = CGSize.zero
    
    var yIdx: Int = -1 // the line of trajectory, default -1
    
    public init(danmakuModel: HJDanmakuModel) {
        self.danmakuModel = danmakuModel
    }
    
}

//_______________________________________________________________________________________________________________

public class HJDanmakuSource {
    
    var spinLock: OSSpinLock = OS_SPINLOCK_INIT
    var danmakuAgents: Array<HJDanmakuAgent> = Array<HJDanmakuAgent>.init()
    
    static func danmakuSource(withModel mode: HJDanmakuMode) -> HJDanmakuSource {
        return mode == .HJDanmakuModeLive ? HJDanmakuLiveSource.init(): HJDanmakuVideoSource.init()
    }
    
    public func prepareDanmakus(_ danmakus: Array<HJDanmakuModel>, completion: @escaping () -> Swift.Void) {
        assert(false, "subClass implementation")
    }
    
    public func sendDanmaku(_ danmaku: HJDanmakuMode, forceRender force: Bool) {
        assert(false, "subClass implementation")
    }
    
    public func sendDanmakus(_ danmakus: Array<HJDanmakuMode>) {
        assert(false, "subClass implementation")
    }
    
    public func fetchDanmakuAgents(forTime time: HJDanmakuTime) -> Array<HJDanmakuMode>? {
        assert(false, "subClass implementation");
        return nil
    }
}

public class HJDanmakuVideoSource: HJDanmakuSource {
    
    override public func prepareDanmakus(_ danmakus: Array<HJDanmakuModel>, completion: @escaping () -> Swift.Void) {
        assert(false, "subClass implementation")
    }
    
}

public class HJDanmakuLiveSource: HJDanmakuSource {
    
    override public func prepareDanmakus(_ danmakus: Array<HJDanmakuModel>, completion: @escaping () -> Swift.Void) {
        assert(false, "subClass implementation")
    }
    
}

//_______________________________________________________________________________________________________________

public protocol HJDanmakuViewDelegate : NSObjectProtocol {
    
    // preparate completed. you can start render after callback
    func prepareCompletedWithDanmakuView(_ danmakuView: HJDanmakuView)
    
    // called before render. return NO will ignore danmaku
    func danmakuView(_ danmakuView: HJDanmakuView, shouldRenderDanmaku danmaku: HJDanmakuModel) -> Bool
    
    // display customization
    func danmakuView(_ danmakuView: HJDanmakuView, willDisplayCell cell: HJDanmakuCell, danmaku: HJDanmakuModel)
    func danmakuView(_ danmakuView: HJDanmakuView, didEndDisplayCell cell: HJDanmakuCell, danmaku: HJDanmakuModel)
    
    // selection customization
    func danmakuView(_ danmakuView: HJDanmakuView, shouldSelectCell cell: HJDanmakuCell, danmaku: HJDanmakuModel)
    func danmakuView(_ danmakuView: HJDanmakuView, didSelectCell cell: HJDanmakuCell, danmaku: HJDanmakuModel)
    
}

extension HJDanmakuViewDelegate {
    
    func prepareCompleted(_ danmakuView: HJDanmakuView) {}
    func danmakuView(_ danmakuView: HJDanmakuView, shouldRenderDanmaku danmaku: HJDanmakuModel) -> Bool {return true}
    
    func danmakuView(_ danmakuView: HJDanmakuView, willDisplayCell cell: HJDanmakuCell, danmaku: HJDanmakuModel) {}
    func danmakuView(_ danmakuView: HJDanmakuView, didEndDisplayCell cell: HJDanmakuCell, danmaku: HJDanmakuModel) {}
    
    func danmakuView(_ danmakuView: HJDanmakuView, shouldSelectCell cell: HJDanmakuCell, danmaku: HJDanmakuModel) {}
    func danmakuView(_ danmakuView: HJDanmakuView, didSelectCell cell: HJDanmakuCell, danmaku: HJDanmakuModel) {}

}

//_______________________________________________________________________________________________________________

public protocol HJDanmakuViewDateSource : NSObjectProtocol {
    
    // variable cell width support
    func danmakuView(_ danmakuView: HJDanmakuView, widthForDanmaku danmaku: HJDanmakuModel) -> Float
    
    // cell display. implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    func danmakuView(_ danmakuView: HJDanmakuView, cellForDanmaku danmaku: HJDanmakuModel) -> HJDanmakuCell
    
    // current play time, unit second, must implementation when videoModel
    func playTimeWithDanmakuView(_ danmakuView: HJDanmakuView) -> Float
    
    // play buffer status, when YES, stop render new danmaku, rendered danmaku in screen will continue anim until disappears, only valid when videoModel
    func bufferingWithDanmakuView(_ danmakuView: HJDanmakuView) -> Bool
    
}

extension HJDanmakuViewDateSource {
    
    func playTimeWithDanmakuView(_ danmakuView: HJDanmakuView) -> Float {return 0}
    
    func bufferingWithDanmakuView(_ danmakuView: HJDanmakuView) -> Bool {return false}
    
}

//_______________________________________________________________________________________________________________

fileprivate let HJFrameInterval: Float = 0.2

open class HJDanmakuView: UIView {
    
    weak open var dataSource: HJDanmakuViewDateSource?
    weak open var delegate: HJDanmakuViewDelegate?
    
    public private(set) var isPrepared = false
    public private(set) var isPlaying = false
    
    public let configuration: HJDanmakuConfiguration
    
    var reuseLock: OSSpinLock = OS_SPINLOCK_INIT
    lazy var renderQueue: DispatchQueue = {
        return DispatchQueue.init(label: "com.olinone.danmaku.renderQueue")
    }()
    
    var toleranceCount: Int
    
    var danmakuSource: HJDanmakuSource
    lazy var sourceQueue: OperationQueue = {
        var newSourceQueue = OperationQueue.init()
        newSourceQueue.name = "com.olinone.danmaku.sourceQueue"
        newSourceQueue.maxConcurrentOperationCount = 1
        return newSourceQueue
    }()
    
    lazy var displayLink: CADisplayLink = {
        var displayLink = CADisplayLink.init(target: self, selector: #selector(update))
        displayLink.frameInterval = Int(60.0 * HJFrameInterval)
        displayLink.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        return displayLink
    }()
    var playTime: HJDanmakuTime = HJDanmakuTime.init(time: 0, interval: HJFrameInterval)
    
    var cellClassInfo: Dictionary = Dictionary<String, HJDanmakuCell.Type>.init()
    var cellReusePool: Dictionary = Dictionary<String, Array<HJDanmakuCell>>.init()
    
    var danmakuQueuePool: Array = Array<HJDanmakuAgent>.init()
    var renderingDanmakus: Array = Array<HJDanmakuAgent>.init()
    
    var LRRetainer: Dictionary = Dictionary<NSNumber, HJDanmakuAgent>.init()
    var FTRetainer: Dictionary = Dictionary<NSNumber, HJDanmakuAgent>.init()
    var FBRetainer: Dictionary = Dictionary<NSNumber, HJDanmakuAgent>.init()
    
    var selectDanmakuAgent: HJDanmakuAgent?
    
    public init(frame: CGRect, configuration: HJDanmakuConfiguration) {
        self.configuration = configuration
        self.toleranceCount = Int(fabsf(self.configuration.tolerance) / HJFrameInterval)
        self.toleranceCount = max(self.toleranceCount, 1)
        self.danmakuSource = HJDanmakuSource.danmakuSource(withModel: configuration.danmakuMode)
        
        super.init(frame: frame)
        self.clipsToBounds = true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // you can prepare with nil when liveModel
    public func prepareDanmakus(_ danmakus: Array<HJDanmakuModel>) {
        self.isPrepared = false
        self.stop()
        
        if danmakus.count == 0 {
            self.isPrepared = true
            onMainThreadAsync {
                self.delegate?.prepareCompletedWithDanmakuView(self)
            }
            return
        }
        
        self.danmakuSource.prepareDanmakus(danmakus, completion: {
            self.preloadDanmakusWhenPrepare()
            self.isPrepared = true
            onMainThreadAsync {
                self.delegate?.prepareCompletedWithDanmakuView(self)
            }
        })
    }

    // be sure to call -prepareDanmakus before -play, when isPrepared is NO, call will be invalid
    public func play() {
        if self.configuration.duration <= 0 {
            assert(false, "configuration nil or duration <= 0")
            return
        }
        
        if !self.isPrepared {
            assert(false, "isPrepared is NO!")
            return
        }
        
        if self.isPlaying {
            return
        }
        self.isPlaying = true
        self.resumeDisplayingDanmakus()
        self.displayLink.isPaused = false;
    }
    
    public func pause() {
        if !self.isPlaying {
            return
        }
        self.isPlaying = false
        self.displayLink.isPaused = true
        self.pauseDisplayingDanmakus()
    }
    
    public func stop() {
        self.isPlaying = false
        self.displayLink.invalidate()
        self.playTime = HJDanmakuTime.init(time: 0, interval: HJFrameInterval)
        renderQueue.async {
            self.danmakuQueuePool.removeAll()
        }
        self.clearScreen()
    }
    
    public func clearScreen() {
        self.recycleDanmakuAgents(self.renderingDanmakus)
        self.renderQueue.async {
            self.renderingDanmakus.removeAll()
            self.LRRetainer.removeAll()
            self.FTRetainer.removeAll()
            self.FBRetainer.removeAll()
        }
    }
    
    override open func sizeToFit() {
        super.sizeToFit()
        let danmakuAgents = self.visibleDanmakuAgents()
        onMainThreadAsync {
            let midX = self.bounds.midX
            let height = self.bounds.height
            for danmakuAgent in danmakuAgents {
                if danmakuAgent.danmakuModel.danmakuType != .HJDanmakuTypeLR {
                    var centerPoint = danmakuAgent.danmakuCell!.center
                    centerPoint.x = midX
                    danmakuAgent.danmakuCell!.center = centerPoint
                    if danmakuAgent.danmakuModel.danmakuType == .HJDanmakuTypeFB {
                        var rect: CGRect = danmakuAgent.danmakuCell!.frame
                        rect.origin.y = height - self.configuration.cellHeight * CGFloat(danmakuAgent.yIdx + 1)
                        danmakuAgent.danmakuCell!.frame = rect
                    }
                }
            }
        }
    }
    
    /* send customization. when force, renderer will draw the danmaku immediately and ignore the maximum quantity limit.
     you should call -sendDanmakus: instead of -sendDanmaku:forceRender: to send the danmakus from a remote servers
     */
    public func sendDanmaku(_ danmaku: HJDanmakuMode, forceRender force: Bool) {
        self.danmakuSource.sendDanmaku(danmaku, forceRender: force)
        
        if force {
            var time = HJDanmakuTime.init(time: 0, interval: HJFrameInterval)
            time.time = (self.dataSource?.playTimeWithDanmakuView(self))!
            self.loadDanmakusFromSource(forTime: time)
        }
    }
    
    public func sendDanmakus(_ danmakus: Array<HJDanmakuMode>) {
        self.danmakuSource.sendDanmakus(danmakus)
    }
    
    // returns nil if cell is not visible
    public func danmakuForVisibleCell(_ danmakuCell: HJDanmakuCell) -> HJDanmakuModel? {
        let danmakuAgents = self.visibleDanmakuAgents()
        for danmakuAgent in danmakuAgents {
            if danmakuAgent.danmakuCell == danmakuCell {
                return danmakuAgent.danmakuModel
            }
        }
        return nil
    }
    
    public var visibleCells: Array<HJDanmakuCell> {
        get {
            var visibleCells = Array<HJDanmakuCell>()
            renderQueue.sync {
                for danmakuAgent in self.renderingDanmakus {
                    let danmakuCell = danmakuAgent.danmakuCell
                    if let cell = danmakuCell {
                        visibleCells.append(cell)
                    }
                }
            }
            return visibleCells;
        }
    }
    
    func visibleDanmakuAgents() -> Array<HJDanmakuAgent> {
        var renderingDanmakus: Array<HJDanmakuAgent>!
        renderQueue.sync {
            renderingDanmakus = Array.init(self.renderingDanmakus)
        }
        return renderingDanmakus;
    }
}

extension HJDanmakuView {
    
    func preloadDanmakusWhenPrepare() {
        
    }
    
    func pauseDisplayingDanmakus() {
        
    }
    
    func resumeDisplayingDanmakus() {
        
    }
    
    // MARK: - Render
    
    func update() {
        
    }
    
    func loadDanmakusFromSource(forTime time: HJDanmakuTime) {
        
    }
    
    func renderDanmakus(forTime time: HJDanmakuTime, buffering isBuffering: Bool) {
        
    }
    
    func renderDisplayingDanmakus(forTime time: HJDanmakuTime) {
        
    }
    
    func recycleDanmakuAgents(_ danmakuAgents: Array<HJDanmakuAgent>) {
        
    }
    
    func renderNewDanmakus(forTime time: HJDanmakuTime) {
        
    }
    
    func renderNewDanmakus(_ danmakuAgent: HJDanmakuAgent, forTime time: HJDanmakuTime) {
        
    }
    
    func removeExpiredDanmakus(forTime time: HJDanmakuTime) {
        
    }
    
}

extension HJDanmakuView {
    
    public func register(_ cellClass: HJDanmakuCell.Type, forCellReuseIdentifier identifier: String) {
        self.cellClassInfo[identifier] = cellClass
    }
    
    public func dequeueReusableCell(withIdentifier identifier: String) -> HJDanmakuCell? {
        let cells = self.cellReusePool[identifier]
        if cells?.count == 0 {
            let cellClass: HJDanmakuCell.Type? = self.cellClassInfo[identifier]
            if let cellType = cellClass {
                let cell = cellType.init(reuseIdentifier: identifier)
                return cell
            }
            return nil
        }
        OSSpinLockLock(&reuseLock);
        let cell: HJDanmakuCell = cells!.last!
        OSSpinLockUnlock(&reuseLock);
        cell.zIndex = 0
        cell.prepareForReuse()
        return cell
    }
    
    func recycleCellToReusePool(_ danmakuCell: HJDanmakuCell) {
        let identifier: String = danmakuCell.reuseIdentifier
        OSSpinLockLock(&reuseLock);
        var cells = self.cellReusePool[identifier]
        if cells == nil {
            cells = Array.init()
        }
        cells!.append(danmakuCell)
        OSSpinLockUnlock(&reuseLock);
    }
    
}
