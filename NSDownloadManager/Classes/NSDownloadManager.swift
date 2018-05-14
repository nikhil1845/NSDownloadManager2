//
//
//  PinterestLayoutDelegate.swift
//  ImagesDownloadAndCache
//
//  Created by SEPL MAC on 10/05/18.
//  Copyright © 2018 Medigarage Studios LTD. All rights reserved.
//

import UIKit

final public class NSDownloadManager: NSObject {
    
    public typealias DownloadCompletionBlock = (_ error : Error?, _ fileUrl:Data?) -> Void
    public typealias DownloadProgressBlock = (_ progress : CGFloat) -> Void
    
    // MARK :- Properties
    
    var session: URLSession = URLSession()
    var ongoingDownloads: [String : NSDownloadObject] = [:]
    var cache:NSCache<AnyObject, AnyObject>! = NSCache()
 

    public static let shared: NSDownloadManager = { return NSDownloadManager() }()

    //MARK:- Public methods
    
    public func dowloadFile(withRequest request: URLRequest,
                            inDirectory directory: String? = nil,
                            withName fileName: String? = nil,
                            onProgress progressBlock:DownloadProgressBlock? = nil,
                            onCompletion completionBlock:@escaping DownloadCompletionBlock) -> String? {
        
        if let _ = self.ongoingDownloads[(request.url?.absoluteString)!] {
            print("Already in progress")
            return nil
        }
      if let cachedImage = self.cache.object(forKey: (request.url?.absoluteString as NSString?)!)
      {
        print("Already exist")
        completionBlock(nil,cachedImage as? Data)
        return nil
      }
        
        let downloadTask = self.session.downloadTask(with: request)
        let download = NSDownloadObject(downloadTask: downloadTask,
                                        progressBlock: progressBlock,
                                        completionBlock: completionBlock,
                                        fileName: fileName,
                                        directoryName: directory,
                                        url: request.url?.absoluteString)
      
        let key = (request.url?.absoluteString)!
        self.ongoingDownloads[key] = download
        downloadTask.resume()
        return key;
    }
    
    public func currentDownloads() -> [String] {
        return Array(self.ongoingDownloads.keys)
    }
    
    public func cancelAllDownloads() {
        for (_, download) in self.ongoingDownloads {
            let downloadTask = download.downloadTask
            downloadTask.cancel()
        }
        self.ongoingDownloads.removeAll()
    }
    
    public func cancelDownload(forUniqueKey key:String?) {
        let downloadStatus = self.isDownloadInProgress(forUniqueKey: key)
        let presence = downloadStatus.0
        if presence
        {
            if let download = downloadStatus.1 {
                download.downloadTask.cancel()
                self.ongoingDownloads.removeValue(forKey: key!)
            }
        }
    }
    
    public func isDownloadInProgress(forKey key:String?) -> Bool {
        let downloadStatus = self.isDownloadInProgress(forUniqueKey: key)
        return downloadStatus.0
    }
    
    public func alterBlocksForOngoingDownload(withUniqueKey key:String?,
                                     setProgress progressBlock:DownloadProgressBlock?,
                                     setCompletion completionBlock:@escaping DownloadCompletionBlock) {
        let downloadStatus = self.isDownloadInProgress(forUniqueKey: key)
        let presence = downloadStatus.0
        if presence {
            if let download = downloadStatus.1 {
                download.progressBlock = progressBlock
                download.completionBlock = completionBlock
            }
        }
    }
    //MARK:- Private methods
    
    private override init() {
        super.init()
        let sessionConfiguration = URLSessionConfiguration.default
        self.session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }

    private func isDownloadInProgress(forUniqueKey key:String?) -> (Bool, NSDownloadObject?) {
        guard let key = key else { return (false, nil) }
        for (uniqueKey, download) in self.ongoingDownloads {
            if key == uniqueKey {
                return (true, download)
            }
        }
        return (false, nil)
    }
    
}

extension NSDownloadManager : URLSessionDelegate, URLSessionDownloadDelegate {
    
    // MARK:- Delegates
    
    public func urlSession(_ session: URLSession,
                             downloadTask: URLSessionDownloadTask,
                             didFinishDownloadingTo location: URL) {
        
        let key = (downloadTask.originalRequest?.url?.absoluteString)!
        if let download = self.ongoingDownloads[key]  {
            if let response = downloadTask.response {
                let statusCode = (response as! HTTPURLResponse).statusCode
                
                guard statusCode < 400 else {
                    let error = NSError(domain:"HttpError", code:statusCode, userInfo:[NSLocalizedDescriptionKey : HTTPURLResponse.localizedString(forStatusCode: statusCode)])
                    OperationQueue.main.addOperation({
                        download.completionBlock(error,nil)
                    })
                    return
                }
 
                if let data = try? Data(contentsOf: location)
                {
 
                    OperationQueue.main.addOperation({
                      self.cache.setObject(data as AnyObject, forKey: download.url as AnyObject)
                      download.completionBlock(nil,data)
                    })
                    
                } 
                
            }
        }
        self.ongoingDownloads.removeValue(forKey:key)
    }
    
    public func urlSession(_ session: URLSession,
                             downloadTask: URLSessionDownloadTask,
                             didWriteData bytesWritten: Int64,
                             totalBytesWritten: Int64,
                             totalBytesExpectedToWrite: Int64) {
        
        if let download = self.ongoingDownloads[(downloadTask.originalRequest?.url?.absoluteString)!],
            let progressBlock = download.progressBlock {
            let progress : CGFloat = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
            OperationQueue.main.addOperation({
                progressBlock(progress)
            })
        }
    }
    
    public func urlSession(_ session: URLSession,
                             task: URLSessionTask,
                             didCompleteWithError error: Error?) {
        
        if let error = error {
            let downloadTask = task as! URLSessionDownloadTask
            let key = (downloadTask.originalRequest?.url?.absoluteString)!
            if let download = self.ongoingDownloads[key] {
                OperationQueue.main.addOperation({
                    download.completionBlock(error,nil)
                })
            }
            self.ongoingDownloads.removeValue(forKey:key)
        }
    }

}
