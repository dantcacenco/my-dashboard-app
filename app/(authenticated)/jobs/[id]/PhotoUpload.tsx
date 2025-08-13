'use client';

import { useState } from 'react';
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Camera, Upload, X, Image as ImageIcon } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';

interface PhotoUploadProps {
  jobId: string;
}

export default function PhotoUpload({ jobId }: PhotoUploadProps) {
  const [uploading, setUploading] = useState(false);
  const [photos, setPhotos] = useState<any[]>([]);
  const [error, setError] = useState<string | null>(null);
  const supabase = createClientComponentClient();

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    try {
      setError(null);
      setUploading(true);

      const file = event.target.files?.[0];
      if (!file) return;

      // Validate file type
      if (!file.type.startsWith('image/')) {
        setError('Please upload an image file');
        return;
      }

      // Validate file size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        setError('File size must be less than 5MB');
        return;
      }

      // Create unique file name
      const fileExt = file.name.split('.').pop();
      const fileName = `${jobId}/${Date.now()}.${fileExt}`;

      // Upload to storage
      const { data, error: uploadError } = await supabase.storage
        .from('job-photos')
        .upload(fileName, file);

      if (uploadError) throw uploadError;

      // Save photo metadata to database
      const { error: dbError } = await supabase
        .from('job_photos')
        .insert({
          job_id: jobId,
          photo_url: data.path,
          photo_type: 'during', // Default type
          uploaded_by: (await supabase.auth.getUser()).data.user?.id
        });

      if (dbError) throw dbError;

      // Refresh photos list
      fetchPhotos();
      
      // Reset input
      event.target.value = '';
    } catch (error: any) {
      console.error('Upload error:', error);
      setError(error.message || 'Failed to upload photo');
    } finally {
      setUploading(false);
    }
  };

  const fetchPhotos = async () => {
    try {
      const { data, error } = await supabase
        .from('job_photos')
        .select('*')
        .eq('job_id', jobId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setPhotos(data || []);
    } catch (error: any) {
      console.error('Error fetching photos:', error);
    }
  };

  const deletePhoto = async (photoId: string, photoUrl: string) => {
    try {
      // Delete from storage
      const { error: storageError } = await supabase.storage
        .from('job-photos')
        .remove([photoUrl]);

      if (storageError) throw storageError;

      // Delete from database
      const { error: dbError } = await supabase
        .from('job_photos')
        .delete()
        .eq('id', photoId);

      if (dbError) throw dbError;

      fetchPhotos();
    } catch (error: any) {
      console.error('Error deleting photo:', error);
      setError('Failed to delete photo');
    }
  };

  return (
    <div className="space-y-4">
      {error && (
        <Alert variant="destructive">
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      <div className="flex items-center gap-4">
        <input
          type="file"
          accept="image/*"
          onChange={handleFileUpload}
          disabled={uploading}
          className="hidden"
          id="photo-upload"
        />
        <label htmlFor="photo-upload">
          <Button asChild disabled={uploading}>
            <span>
              {uploading ? (
                <>
                  <Upload className="h-4 w-4 mr-2 animate-spin" />
                  Uploading...
                </>
              ) : (
                <>
                  <Camera className="h-4 w-4 mr-2" />
                  Upload Photo
                </>
              )}
            </span>
          </Button>
        </label>
      </div>

      {photos.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-12">
            <ImageIcon className="h-12 w-12 text-muted-foreground mb-4" />
            <p className="text-muted-foreground">No photos uploaded yet</p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          {photos.map((photo) => (
            <Card key={photo.id} className="relative group">
              <CardContent className="p-2">
                <div className="aspect-square relative bg-muted rounded">
                  <ImageIcon className="absolute inset-0 m-auto h-8 w-8 text-muted-foreground" />
                  <Button
                    variant="destructive"
                    size="sm"
                    className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity"
                    onClick={() => deletePhoto(photo.id, photo.photo_url)}
                  >
                    <X className="h-4 w-4" />
                  </Button>
                </div>
                <p className="text-xs text-muted-foreground mt-2">
                  {new Date(photo.created_at).toLocaleDateString()}
                </p>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
