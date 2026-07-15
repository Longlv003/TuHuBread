const fs = require('fs');
const path = require('path');
const https = require('https');

// 3 shops images (Logo + Banner)
const shops = [
  { name: 'shop_001_avatar.jpg', url: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200&auto=format&fit=crop&q=80' },
  { name: 'shop_001_banner.jpg', url: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&auto=format&fit=crop&q=80' },
  { name: 'shop_002_avatar.jpg', url: 'https://images.unsplash.com/photo-1549611016-3a70d82b5040?w=200&auto=format&fit=crop&q=80' },
  { name: 'shop_002_banner.jpg', url: 'https://images.unsplash.com/photo-1549611016-3a70d82b5040?w=800&auto=format&fit=crop&q=80' },
  { name: 'shop_003_avatar.jpg', url: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=200&auto=format&fit=crop&q=80' },
  { name: 'shop_003_banner.jpg', url: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&auto=format&fit=crop&q=80' }
];

// 9 categories images
const categories = [
  { name: 'cat_1.jpg', url: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&auto=format&fit=crop&q=80' }, // Bánh Mì Thịt
  { name: 'cat_2.jpg', url: 'https://images.unsplash.com/photo-1554522723-b2a47cb105e3?w=400&auto=format&fit=crop&q=80' }, // Bánh Mì Chay
  { name: 'cat_3.jpg', url: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=400&auto=format&fit=crop&q=80' }, // Trà Sữa
  { name: 'cat_4.jpg', url: 'https://images.unsplash.com/photo-1507133750040-4a8f57021571?w=400&auto=format&fit=crop&q=80' }, // Cà Phê
  { name: 'cat_5.jpg', url: 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400&auto=format&fit=crop&q=80' }, // Nước Ép & Sinh Tố
  { name: 'cat_6.jpg', url: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400&auto=format&fit=crop&q=80' }, // Đồ Ăn Kèm
  { name: 'cat_7.jpg', url: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&auto=format&fit=crop&q=80' }, // Tráng Miệng
  { name: 'cat_8.jpg', url: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&auto=format&fit=crop&q=80' }, // Combo
  { name: 'cat_9.jpg', url: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400&auto=format&fit=crop&q=80' }  // Ăn Sáng
];

// 27 products images (3 products per category * 9 categories)
const products = [];
const productUrls = [
  'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=80',
  'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500&auto=format&fit=crop&q=80',
  'https://images.unsplash.com/photo-1549611016-3a70d82b5040?w=500&auto=format&fit=crop&q=80',
  'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500&auto=format&fit=crop&q=80',
  'https://images.unsplash.com/photo-1507133750040-4a8f57021571?w=500&auto=format&fit=crop&q=80',
  'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=500&auto=format&fit=crop&q=80',
  'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500&auto=format&fit=crop&q=80',
  'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop&q=80',
  'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500&auto=format&fit=crop&q=80'
];

for (let catIdx = 1; catIdx <= 9; catIdx++) {
  for (let prodIdx = 1; prodIdx <= 3; prodIdx++) {
    const urlIdx = (catIdx + prodIdx) % productUrls.length;
    products.push({
      name: `prod_${catIdx}_${prodIdx}.jpg`,
      url: productUrls[urlIdx]
    });
  }
}

const catDir = path.join(__dirname, '../public/images/categories');
const prodDir = path.join(__dirname, '../public/images/products');
const shopDir = path.join(__dirname, '../public/images/shops');

// Create directories if not exist
if (!fs.existsSync(catDir)) fs.mkdirSync(catDir, { recursive: true });
if (!fs.existsSync(prodDir)) fs.mkdirSync(prodDir, { recursive: true });
if (!fs.existsSync(shopDir)) fs.mkdirSync(shopDir, { recursive: true });

function downloadFile(url, destPath) {
  return new Promise((resolve, reject) => {
    // If download fails, write a basic placeholder file
    const file = fs.createWriteStream(destPath);
    https.get(url, (response) => {
      if (response.statusCode !== 200) {
        reject(new Error(`Failed to download: Status Code ${response.statusCode}`));
        return;
      }
      response.pipe(file);
      file.on('finish', () => {
        file.close();
        console.log(`Downloaded: ${path.basename(destPath)}`);
        resolve();
      });
    }).on('error', (err) => {
      fs.unlink(destPath, () => {});
      reject(err);
    });
  });
}

async function run() {
  console.log("Starting download of category images...");
  for (const cat of categories) {
    const dest = path.join(catDir, cat.name);
    try {
      await downloadFile(cat.url, dest);
    } catch (err) {
      console.error(`Error downloading category ${cat.name}:`, err.message);
      // Fallback: ghi file trong suot hoặc placeholder
      fs.writeFileSync(dest, '');
    }
  }

  console.log("\nStarting download of product images...");
  for (const prod of products) {
    const dest = path.join(prodDir, prod.name);
    try {
      await downloadFile(prod.url, dest);
    } catch (err) {
      console.error(`Error downloading product ${prod.name}:`, err.message);
      fs.writeFileSync(dest, '');
    }
  }

  console.log("\nStarting download of shop images...");
  for (const shop of shops) {
    const dest = path.join(shopDir, shop.name);
    try {
      await downloadFile(shop.url, dest);
    } catch (err) {
      console.error(`Error downloading shop image ${shop.name}:`, err.message);
      fs.writeFileSync(dest, '');
    }
  }
  console.log("\nDownload Done!");
}

run();
