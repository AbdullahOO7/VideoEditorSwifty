//
//  TestClass.swift
//  VideoEditor
//
//  Created by Muhammad Abdullah on 12/20/19.
//  Copyright © 2019 Thai Cao Ngoc. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit

class TestClass
{
         func shareClicked() {

            let url = URL(string:"https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")!

            DispatchQueue.global(qos: .background).async {

                if let urlData = try? Data(contentsOf: url) {


                    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!

                    let fileUrl = URL(fileURLWithPath: documentsPath).appendingPathComponent("fffffff.mp4")

                    if FileManager.default.fileExists(atPath:fileUrl.path) {

                        try? FileManager.default.removeItem(at:fileUrl)

                        print("removed")
                    }

                    try? urlData.write(to: fileUrl)


                    self.merge(video: fileUrl.path, withForegroundImage:UIImage(named: "images.png")!, completion: { (uuu) in

                                DispatchQueue.main.async {

                                    self.play(uuu!)
                                }

                            })


                    }

            }

        }
        func play(_ url : URL) {

            DispatchQueue.main.async {

                let vc = AVPlayerViewController()

                vc.player = AVPlayer(url: url)

                vc.player?.externalPlaybackVideoGravity = AVLayerVideoGravity.resizeAspect

            //    self.present(vc, animated: true, completion: nil)

            }

        }
        private func addAudioTrack(composition: AVMutableComposition, videoUrl: URL) {


            let videoUrlAsset = AVURLAsset(url: videoUrl, options: nil)

            let audioTracks = videoUrlAsset.tracks(withMediaType: AVMediaType.audio)

            let compositionAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!

            for audioTrack in audioTracks {
                try! compositionAudioTrack.insertTimeRange(audioTrack.timeRange, of: audioTrack, at: CMTime.zero)
            }
        }


        func merge(
            video videoPath: String,
            withForegroundImage foregroundImage: UIImage,
            completion: @escaping (URL?) -> Void) -> () {

            let videoUrl = URL(fileURLWithPath: videoPath)
            let videoUrlAsset = AVURLAsset(url: videoUrl, options: nil)

            // Setup `mutableComposition` from the existing video
            let mutableComposition = AVMutableComposition()
            let videoAssetTrack = videoUrlAsset.tracks(withMediaType: AVMediaType.video).first!
            let videoCompositionTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
            videoCompositionTrack?.preferredTransform = videoAssetTrack.preferredTransform
            try! videoCompositionTrack?.insertTimeRange(CMTimeRange(start:CMTime.zero, duration:videoAssetTrack.timeRange.duration), of: videoAssetTrack, at: CMTime.zero)

            addAudioTrack(composition: mutableComposition, videoUrl: videoUrl)

            let videoSize: CGSize = (videoCompositionTrack?.naturalSize)!
            let frame = CGRect(x: 0.0, y: 0.0, width: videoSize.width, height: videoSize.height)
            let imageLayer = CALayer()
            imageLayer.contents = foregroundImage.cgImage
            imageLayer.frame = CGRect(x: 0.0, y: 0.0, width:50, height:50)


            let videoLayer = CALayer()
            videoLayer.frame = frame
            let animationLayer = CALayer()
            animationLayer.frame = frame
            animationLayer.addSublayer(videoLayer)
            animationLayer.addSublayer(imageLayer)

            let videoComposition = AVMutableVideoComposition(propertiesOf: (videoCompositionTrack?.asset!)!)
            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: animationLayer)

            let documentDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
            let documentDirectoryUrl = URL(fileURLWithPath: documentDirectory)
            let destinationFilePath = documentDirectoryUrl.appendingPathComponent("result.mp4")

            do {

                if FileManager.default.fileExists(atPath: destinationFilePath.path) {

                    try FileManager.default.removeItem(at: destinationFilePath)

                    print("removed")
                }



            } catch {

                print(error)
            }


            let exportSession = AVAssetExportSession( asset: mutableComposition, presetName: AVAssetExportPresetHighestQuality)!

           exportSession.videoComposition = videoComposition
            exportSession.outputURL = destinationFilePath
            exportSession.outputFileType = AVFileType.mp4
            exportSession.exportAsynchronously { [weak exportSession] in
                if let strongExportSession = exportSession {
                    completion(strongExportSession.outputURL!)

                    //self.play(strongExportSession.outputURL!)
                }
            }

        }

    }

