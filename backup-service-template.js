// Service Pro Backup Service
// To be run on Windows office computer via Task Scheduler

const { S3Client, ListObjectsV2Command, GetObjectCommand } = require('@aws-sdk/client-s3');
const { createClient } = require('@supabase/supabase-js');
const nodemailer = require('nodemailer');
const fs = require('fs-extra');
const path = require('path');
const archiver = require('archiver');

// Configuration
const config = {
  supabase: {
    url: process.env.SUPABASE_URL,
    key: process.env.SUPABASE_SERVICE_KEY
  },
  idrive: {
    endpoint: 'https://s3.us-west-1.idrivee2.com',
    accessKeyId: process.env.IDRIVE_ACCESS_KEY,
    secretAccessKey: process.env.IDRIVE_SECRET_KEY,
    bucket: 'service-pro-media'
  },
  backup: {
    basePath: 'C:\\ServicePro\\Backups',
    retentionDays: 90,
    emailTo: 'dantcacenco@gmail.com',
    emailFrom: 'backup@service-pro.com'
  }
};

// S3 Client for IDrive e2
const s3Client = new S3Client({
  endpoint: config.idrive.endpoint,
  region: 'us-west-1',
  credentials: {
    accessKeyId: config.idrive.accessKeyId,
    secretAccessKey: config.idrive.secretAccessKey
  }
});

// Supabase Client
const supabase = createClient(config.supabase.url, config.supabase.key);

// Email Transporter
const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD
  }
});

class BackupService {
  constructor() {
    this.backupDate = new Date().toISOString().split('T')[0];
    this.backupPath = path.join(config.backup.basePath, this.backupDate);
    this.stats = {
      startTime: new Date(),
      dbRecords: 0,
      filesDownloaded: 0,
      totalSize: 0,
      errors: []
    };
  }

  async run() {
    console.log(`Starting backup for ${this.backupDate}...`);
    
    try {
      // Create backup directory
      await fs.ensureDir(this.backupPath);
      
      // Step 1: Backup database
      await this.backupDatabase();
      
      // Step 2: Backup files from IDrive
      await this.backupFiles();
      
      // Step 3: Create archive
      await this.createArchive();
      
      // Step 4: Cleanup old backups
      await this.cleanupOldBackups();
      
      // Step 5: Send success email
      await this.sendReport('SUCCESS');
      
      console.log('Backup completed successfully!');
    } catch (error) {
      console.error('Backup failed:', error);
      this.stats.errors.push(error.message);
      await this.sendReport('FAILED');
      process.exit(1);
    }
  }

  async backupDatabase() {
    console.log('Backing up database...');
    const dbPath = path.join(this.backupPath, 'database');
    await fs.ensureDir(dbPath);

    // Export each table
    const tables = ['jobs', 'customers', 'proposals', 'invoices', 'payment_stages'];
    
    for (const table of tables) {
      const { data, error } = await supabase
        .from(table)
        .select('*');
      
      if (error) throw error;
      
      // Save as JSON
      await fs.writeJson(
        path.join(dbPath, `${table}.json`),
        data,
        { spaces: 2 }
      );
      
      this.stats.dbRecords += data.length;
    }
  }

  async backupFiles() {
    console.log('Backing up files from IDrive...');
    const filesPath = path.join(this.backupPath, 'files');
    await fs.ensureDir(filesPath);

    // Get last backup date
    const lastBackupDate = await this.getLastBackupDate();
    
    // List objects modified since last backup
    const command = new ListObjectsV2Command({
      Bucket: config.idrive.bucket,
      Prefix: 'job-photos/'
    });

    const response = await s3Client.send(command);
    const files = response.Contents || [];

    // Filter files modified since last backup
    const newFiles = lastBackupDate 
      ? files.filter(f => new Date(f.LastModified) > new Date(lastBackupDate))
      : files;

    console.log(`Found ${newFiles.length} new files to backup`);

    // Download each file
    for (const file of newFiles) {
      const getCommand = new GetObjectCommand({
        Bucket: config.idrive.bucket,
        Key: file.Key
      });

      const response = await s3Client.send(getCommand);
      const filePath = path.join(filesPath, file.Key);
      
      await fs.ensureDir(path.dirname(filePath));
      await fs.writeFile(filePath, response.Body);
      
      this.stats.filesDownloaded++;
      this.stats.totalSize += file.Size;
    }
  }

  async createArchive() {
    console.log('Creating archive...');
    
    return new Promise((resolve, reject) => {
      const output = fs.createWriteStream(
        path.join(config.backup.basePath, `${this.backupDate}.zip`)
      );
      
      const archive = archiver('zip', {
        zlib: { level: 9 },
        password: process.env.BACKUP_PASSWORD
      });

      output.on('close', resolve);
      archive.on('error', reject);

      archive.pipe(output);
      archive.directory(this.backupPath, false);
      archive.finalize();
    });
  }

  async cleanupOldBackups() {
    console.log('Cleaning up old backups...');
    
    const files = await fs.readdir(config.backup.basePath);
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - config.backup.retentionDays);

    for (const file of files) {
      const filePath = path.join(config.backup.basePath, file);
      const stats = await fs.stat(filePath);
      
      if (stats.birthtime < cutoffDate) {
        await fs.remove(filePath);
        console.log(`Removed old backup: ${file}`);
      }
    }
  }

  async getLastBackupDate() {
    const markerFile = path.join(config.backup.basePath, 'last-backup.txt');
    
    if (await fs.pathExists(markerFile)) {
      return await fs.readFile(markerFile, 'utf-8');
    }
    
    return null;
  }

  async sendReport(status) {
    const duration = Math.round((new Date() - this.stats.startTime) / 1000 / 60);
    const sizeMB = (this.stats.totalSize / 1024 / 1024).toFixed(2);

    const subject = `Service Pro Weekly Backup - ${status} - ${this.backupDate}`;
    
    let html = `
      <h2>Backup ${status === 'SUCCESS' ? '✅ Successfully Completed' : '❌ FAILED - NEEDS ATTENTION'}</h2>
      
      <h3>Summary</h3>
      <ul>
        <li>Date: ${this.backupDate}</li>
        <li>Duration: ${duration} minutes</li>
        <li>Database Records: ${this.stats.dbRecords}</li>
        <li>Files Downloaded: ${this.stats.filesDownloaded}</li>
        <li>Total Size: ${sizeMB} MB</li>
        <li>Location: ${this.backupPath}</li>
      </ul>
    `;

    if (this.stats.errors.length > 0) {
      html += `
        <h3>Errors</h3>
        <ul>
          ${this.stats.errors.map(e => `<li>${e}</li>`).join('')}
        </ul>
      `;
    }

    html += `
      <hr>
      <p>Next scheduled backup: ${this.getNextBackupDate()}</p>
      <p><small>Automated by Service Pro Backup System</small></p>
    `;

    await transporter.sendMail({
      from: config.backup.emailFrom,
      to: config.backup.emailTo,
      subject,
      html
    });

    // Save last backup marker
    await fs.writeFile(
      path.join(config.backup.basePath, 'last-backup.txt'),
      this.backupDate
    );
  }

  getNextBackupDate() {
    const next = new Date();
    next.setDate(next.getDate() + 7);
    return next.toLocaleDateString();
  }
}

// Run backup
if (require.main === module) {
  const backup = new BackupService();
  backup.run().catch(console.error);
}

module.exports = BackupService;
