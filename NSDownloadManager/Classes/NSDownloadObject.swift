//
//NTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit

class NSDownloadObject: NSObject {

    var completionBlock: NSDownloadManager.DownloadCompletionBlock
    var progressBlock: NSDownloadManager.DownloadProgressBlock?
    let downloadTask: URLSessionDownloadTask
    let directoryName: String?
    let fileName:String?
    let url:String?

    
    init(downloadTask: URLSessionDownloadTask,
         progressBlock: NSDownloadManager.DownloadProgressBlock?,
         completionBlock: @escaping NSDownloadManager.DownloadCompletionBlock,
         fileName: String?,
         directoryName: String?,
      url: String?) {
        
        self.downloadTask = downloadTask
        self.completionBlock = completionBlock
        self.progressBlock = progressBlock
        self.fileName = fileName
        self.directoryName = directoryName
        self.url = url
    }
    
}
