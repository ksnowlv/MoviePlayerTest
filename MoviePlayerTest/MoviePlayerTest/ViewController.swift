//
//  ViewController.swift
//  MoviePlayerTest
//
//  Created by ksnowlv on 2019/11/22.
//  Copyright © 2019 ksnowlv. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {
    
    @IBOutlet private weak var playerContainerView: UIView?
    @IBOutlet private weak var startPlayerButton: UIButton?
    @IBOutlet private weak var pausePlayerButton: UIButton?
    
    @IBOutlet private weak var slider: UISlider?
    @IBOutlet private weak var movieTextLabel: UILabel?
    
    private static let observerKeyStatus = "status"
    private static let observerKeyLoadedTimeRanges = "loadedTimeRanges"
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var isPlaying = false
    var parser: Subtitles?
    
    
    private let movieUrl = "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        playMovieFromLocalFile(fileFullName: Bundle.main.path(forResource: "test", ofType:"m4v")!)
        
       // playMovie(movieFile: Bundle.main.path(forResource: "test", ofType:"mp4")!, captionFile: Bundle.main.path(forResource: "test", ofType:"srt")!)
        
//        playMovieOnline(webUrl: movieUrl)
        
    }
    
    deinit {
        player?.currentItem?.removeObserver(self, forKeyPath: ViewController.observerKeyStatus)
        player?.currentItem?.removeObserver(self, forKeyPath: ViewController.observerKeyStatus)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        playerLayer?.frame = playerContainerView!.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        if isPlaying {
            player?.pause()
            player = nil
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        let playerItem: AVPlayerItem = object as! AVPlayerItem
        
        if keyPath == ViewController.observerKeyStatus {
            
            let status =  AVPlayer.Status(rawValue: change?[.newKey] as! Int) ?? AVPlayer.Status.unknown
            
            debugPrint("AVPlayer.Status:\(status)")
            
            switch status {
            case AVPlayer.Status.readyToPlay: do {
                debugPrint("readyToPlay")
            }
                break
                
            case .failed: do {
                debugPrint("failed")
            }
                break
                
            default: break
                
            }
            
        } else if keyPath == ViewController.observerKeyLoadedTimeRanges {
        }
        
    }
    
    //MARK:UI Event
    @IBAction func handleStartPlayerEvent(sender: AnyObject) {
        isPlaying = true
        player?.play()
    }
    
    @IBAction func handlePausePlayerEvent(sender: AnyObject) {
        
        if isPlaying {
            player?.pause()
        }
    }
    
    //MARK:play movie
    func playMovieFromLocalFile(fileFullName: String) -> Bool {
        
        guard FileManager.default.fileExists(atPath: fileFullName) else {
            debugPrint("\(fileFullName) not Found")
            return false
        }
        
        let asset = AVAsset(url: URL(fileURLWithPath: fileFullName))
        let playerItem = AVPlayerItem(asset: asset)
        
        for characteristic in asset.availableMediaCharacteristicsWithMediaSelectionOptions {
            
            debugPrint("\(characteristic)\n")
            
            if let group = asset.mediaSelectionGroup(forMediaCharacteristic: characteristic) {
                for option in group.options {
                    debugPrint("  Option: \(option.displayName)\n")
                }
            }
        }
        
        // Create a group of the legible AVMediaCharacteristics (Subtitles)
        if let group = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.legible) {
            
            let locale = Locale(identifier: "zh")
            // Create an option group to hold the options in the group that match the locale
            let options =
                AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: locale)
            // Assign the first option from options to the variable option
            if let option = options.first {
                // Select the option for the selected locale
                playerItem.select(option, in: group)
            }
        }
        
        player = AVPlayer(playerItem: playerItem)
        player?.appliesMediaSelectionCriteriaAutomatically = false
        
        if playerLayer == nil && player != nil  {
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            playerContainerView?.layer.addSublayer(playerLayer!)
        }
        
        return true
    }
    
    func playMovie(movieFile: String, captionFile: String) -> Bool {
        
        let fileManage = FileManager.default
        guard fileManage.fileExists(atPath: movieFile) && fileManage.fileExists(atPath: captionFile) else {
            debugPrint("movie:\(movieFile)/ or captionFile:\(captionFile)not found")
            return false
        }
        
        
        player =  AVPlayer(url: URL(fileURLWithPath: movieFile))
        
        let asset = AVAsset(url: URL(fileURLWithPath: captionFile))
        
        for characteristic in asset.availableMediaCharacteristicsWithMediaSelectionOptions {
            print("\(characteristic)")
            
            // Retrieve the AVMediaSelectionGroup for the specified characteristic.
            if let group = asset.mediaSelectionGroup(forMediaCharacteristic: characteristic) {
                // Print its options.
                for option in group.options {
                    print("  Option: \(option.displayName)")
                }
            }
        }
        
        if let group = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.legible) {
            let locale = Locale(identifier: "en")
            let options =
                AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: locale)
            if let option = options.first {
                // Select Spanish-language subtitle option
                player?.currentItem!.select(option, in: group)
                print("\(player?.currentItem!.select(option, in: group))")
            }
        }
        
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerContainerView?.layer.addSublayer(playerLayer!)
        
        
        player?.currentItem?.addObserver(self, forKeyPath:ViewController.observerKeyStatus, options:[NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.initial], context: nil)
        player?.currentItem?.addObserver(self, forKeyPath: ViewController.observerKeyLoadedTimeRanges, options: NSKeyValueObservingOptions.new, context: nil)
        
        // Subtitle file
        let subtitleFile = Bundle.main.path(forResource: "test", ofType: "srt")
        let subtitleURL = URL(fileURLWithPath: subtitleFile!)
        
        // Subtitle parser
        parser = Subtitles(file: subtitleURL, encoding: .utf8)
        
        player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: DispatchQueue.main, using: { [weak self] (time: CMTime) in
            
            let currentTime = CMTimeGetSeconds(time)
            
            guard let self = self else {
                return
            }
            
            
            self.movieTextLabel?.text = self.parser?.searchSubtitles(at: currentTime)
            
            let totolCTTime =  self.player?.currentItem?.duration ?? CMTimeMake(value: 0, timescale: 0)
            
            let totalTime  = CMTimeGetSeconds(totolCTTime)
            
            if totalTime > 0 {
                self.slider?.value = Float(currentTime/totalTime)
            }
        })
        
        return true
    }
    
    /// <#Description#>
    /// - Parameter webUrl: <#webUrl description#>
    func playMovieOnline(webUrl: String) -> Void {
        let webVideoUrl = URL(string: webUrl)
        
        player = AVPlayer(url: webVideoUrl!)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerContainerView?.layer.addSublayer(playerLayer!)
        
        
        player?.currentItem?.addObserver(self, forKeyPath:ViewController.observerKeyStatus, options:[NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.initial], context: nil)
        player?.currentItem?.addObserver(self, forKeyPath: ViewController.observerKeyLoadedTimeRanges, options: NSKeyValueObservingOptions.new, context: nil)
        
        player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: DispatchQueue.main, using: { [weak self] (time: CMTime) in
            
            let currentTime = CMTimeGetSeconds(time)
            
            guard let self = self else {
                return
            }
            
            let totolCTTime =  self.player?.currentItem?.duration ?? CMTimeMake(value: 0, timescale: 0)
            
            let totalTime  = CMTimeGetSeconds(totolCTTime)
            
            if totalTime > 0 {
                self.slider?.value = Float(currentTime/totalTime)
            }
            
        })
    }
    
    
    
}

