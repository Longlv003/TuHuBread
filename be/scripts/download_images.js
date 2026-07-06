const fs = require('fs');
const path = require('path');
const https = require('https');

// Danh sách ảnh danh mục chung và danh mục shop cần tải
const categories = [
  {
    name: 'cat_bread.jpg',
    url: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&auto=format&fit=crop&q=80'
  },
  {
    name: 'cat_drink.jpg',
    url: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=400&auto=format&fit=crop&q=80'
  },
  {
    name: 'cat_combo.jpg',
    url: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&auto=format&fit=crop&q=80'
  },
  {
    name: 'scat_best.jpg',
    url: 'https://images.unsplash.com/photo-1572802419224-296b0aeee0d9?w=400&auto=format&fit=crop&q=80'
  },
  {
    name: 'scat_chicken.jpg',
    url: 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=400&auto=format&fit=crop&q=80'
  }
];

// Danh sách ảnh sản phẩm cần tải
const products = [
  {
    name: 'prod_special.jpg',
    url: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500&auto=format&fit=crop&q=80'
  },
  {
    name: 'prod_char_siu.jpg',
    url: 'https://images.unsplash.com/photo-1549611016-3a70d82b5040?w=500&auto=format&fit=crop&q=80'
  },
  {
    name: 'prod_thai_tea.jpg',
    url: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500&auto=format&fit=crop&q=80'
  },
  {
    name: 'prod_combo_tuhu.jpg',
    url: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=80'
  },
  {
    name: 'prod_chicken_shred.jpg',
    url: 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=500&auto=format&fit=crop&q=80'
  },
  {
    name: 'prod_pate_special.jpg',
    url: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop&q=80'
  }
];

// Danh sách ảnh shop cần tải
const shops = [
  {
    name: 'shop_001_avatar.jpg',
    url: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200&auto=format&fit=crop&q=80'
  },
  {
    name: 'shop_001_banner.jpg',
    url: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&auto=format&fit=crop&q=80'
  },
  {
    name: 'shop_002_avatar.jpg',
    url: 'https://images.unsplash.com/photo-1549611016-3a70d82b5040?w=200&auto=format&fit=crop&q=80'
  },
  {
    name: 'shop_002_banner.jpg',
    url: 'https://images.unsplash.com/photo-1549611016-3a70d82b5040?w=600&auto=format&fit=crop&q=80'
  }
];

const catDir = path.join(__dirname, '../public/images/categories');
const prodDir = path.join(__dirname, '../public/images/products');
const shopDir = path.join(__dirname, '../public/images/shops');

// Tạo thư mục nếu chưa tồn tại
if (!fs.existsSync(catDir)) fs.mkdirSync(catDir, { recursive: true });
if (!fs.existsSync(prodDir)) fs.mkdirSync(prodDir, { recursive: true });
if (!fs.existsSync(shopDir)) fs.mkdirSync(shopDir, { recursive: true });

function downloadFile(url, destPath) {
  return new Promise((resolve, reject) => {
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
    }
  }

  console.log("\nStarting download of product images...");
  for (const prod of products) {
    const dest = path.join(prodDir, prod.name);
    try {
      await downloadFile(prod.url, dest);
    } catch (err) {
      console.error(`Error downloading product ${prod.name}:`, err.message);
    }
  }

  console.log("\nStarting download of shop images...");
  for (const shop of shops) {
    const dest = path.join(shopDir, shop.name);
    try {
      await downloadFile(shop.url, dest);
    } catch (err) {
      console.error(`Error downloading shop image ${shop.name}:`, err.message);
    }
  }
  console.log("\nDone!");
}

run();
