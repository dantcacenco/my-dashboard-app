const fs = require('fs');
const path = './app/(authenticated)/jobs/[id]/JobDetailView.tsx';

let content = fs.readFileSync(path, 'utf8');

// Fix openMediaViewer function to properly detect videos
const oldOpenMediaViewer = `  const openMediaViewer = (photos: any[], index: number) => {
    // Format photos for MediaViewer component
    const items = photos.map(photo => ({
      id: photo.id,
      url: photo.photo_url,
      name: photo.caption || 'Job Photo',
      caption: photo.caption,
      type: photo.mime_type?.startsWith('video/') ? 'file' : 'photo',
      mime_type: photo.mime_type
    }))
    
    setViewerItems(items)
    setViewerIndex(index)
    setViewerOpen(true)
  }`;

const newOpenMediaViewer = `  const openMediaViewer = (photos: any[], index: number) => {
    // Format photos for MediaViewer component
    const items = photos.map(photo => ({
      id: photo.id,
      url: photo.photo_url,
      name: photo.caption || 'Media',
      caption: photo.caption,
      type: photo.mime_type?.startsWith('video/') ? 'video' : 'photo',
      mime_type: photo.mime_type
    }))
    
    setViewerItems(items)
    setViewerIndex(index)
    setViewerOpen(true)
  }

  const openFileViewer = (files: any[], index: number) => {
    // Format files for MediaViewer component
    const items = files.map(file => ({
      id: file.id,
      url: file.file_url,
      name: file.file_name,
      caption: file.file_name,
      type: 'file',
      mime_type: file.mime_type || 'application/octet-stream'
    }))
    
    setViewerItems(items)
    setViewerIndex(index)
    setViewerOpen(true)
  }`;

// Replace the function
content = content.replace(oldOpenMediaViewer, newOpenMediaViewer);

// Find and replace the jobFiles display section to add click functionality
const oldFilesSection = /({jobFiles\.length > 0 && \(\s+<div className="space-y-2 mt-4">\s+{jobFiles\.map\(file => \(\s+<div key={file\.id} className="flex items-center justify-between p-3 border rounded">\s+<div className="flex items-center gap-3">\s+<FileText className="h-5 w-5 text-muted-foreground" \/>\s+<div>\s+<p className="font-medium">{file\.file_name}<\/p>\s+<p className="text-sm text-muted-foreground">\s+{new Date\(file\.created_at\)\.toLocaleDateString\(\)}\s+<\/p>\s+<\/div>\s+<\/div>\s+<Button\s+size="sm"\s+variant="outline"\s+>\s+View\s+<\/Button>\s+<\/div>\s+\)\)}\s+<\/div>\s+\)\)}/s;

const newFilesSection = `{jobFiles.length > 0 && (
                <div className="space-y-2 mt-4">
                  {jobFiles.map((file, index) => (
                    <div key={file.id} className="flex items-center justify-between p-3 border rounded">
                      <div className="flex items-center gap-3">
                        <FileText className="h-5 w-5 text-muted-foreground" />
                        <div>
                          <p className="font-medium">{file.file_name}</p>
                          <p className="text-sm text-muted-foreground">
                            {new Date(file.created_at).toLocaleDateString()}
                          </p>
                        </div>
                      </div>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => openFileViewer(jobFiles, index)}
                      >
                        View
                      </Button>
                    </div>
                  ))}
                </div>
              )}`;

// Use a more targeted replacement approach
const fileSectionPattern = /\{jobFiles\.map\(file => \(\s*<div key=\{file\.id\}[\s\S]*?<Button[\s\S]*?View[\s\S]*?<\/Button>[\s\S]*?<\/div>\s*\)\)\}/;

if (fileSectionPattern.test(content)) {
  content = content.replace(fileSectionPattern, `{jobFiles.map((file, index) => (
                    <div key={file.id} className="flex items-center justify-between p-3 border rounded">
                      <div className="flex items-center gap-3">
                        <FileText className="h-5 w-5 text-muted-foreground" />
                        <div>
                          <p className="font-medium">{file.file_name}</p>
                          <p className="text-sm text-muted-foreground">
                            {new Date(file.created_at).toLocaleDateString()}
                          </p>
                        </div>
                      </div>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => openFileViewer(jobFiles, index)}
                      >
                        View
                      </Button>
                    </div>
                  ))}`);
}

fs.writeFileSync(path, content);
console.log('JobDetailView.tsx updated successfully');
