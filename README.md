# 🏡 ElderCare Connect

<div align="center">
  
  ![ElderCare Connect Banner](https://via.placeholder.com/1200x300/4A90E2/FFFFFF?text=ElderCare+Connect)
  
  [![Laravel](https://img.shields.io/badge/Laravel-12.0-FF2D20?style=for-the-badge&logo=laravel&logoColor=white)](https://laravel.com)
  [![PHP](https://img.shields.io/badge/PHP-8.4-777BB4?style=for-the-badge&logo=php&logoColor=white)](https://php.net)
  [![Livewire](https://img.shields.io/badge/Livewire-3.0-FB70A9?style=for-the-badge&logo=livewire&logoColor=white)](https://livewire.laravel.com)
  [![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)
  
  [![Build Status](https://img.shields.io/github/actions/workflow/status/eldercare/connect/tests.yml?style=flat-square)](https://github.com/eldercare/connect/actions)
  [![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
  [![WCAG](https://img.shields.io/badge/WCAG-AA-success?style=flat-square)](https://www.w3.org/WAI/WCAG21/quickref/)
  
  **A modern, accessible web platform for elderly daycare centers**  
  *Built with love for our seniors and their families* 💙
  
  [Live Demo](https://demo.eldercare-connect.com) • [Documentation](docs/) • [Report Bug](issues/) • [Request Feature](issues/)

</div>

---

## ✨ Features at a Glance

<table>
  <tr>
    <td width="50%">
      
### 👴 For Seniors & Families
- 📱 **Mobile-First Design** - Easy access on any device
- 👁️ **Accessibility First** - WCAG AA compliant
- 📅 **Easy Booking** - Simple slot reservation system
- 🎬 **Virtual Tours** - Video galleries and 360° views
- 👥 **Meet Our Staff** - Detailed team profiles
- 💬 **Testimonials** - Real stories from families
      
</td>
    <td width="50%">
      
### 🏢 For Centers & Staff
- 📊 **Admin Dashboard** - Comprehensive management tools
- 📝 **Content Management** - Easy updates without coding
- 📈 **Booking Management** - Track and manage reservations
- 🎯 **Service Showcase** - Highlight your programs
- 📸 **Media Manager** - Photo/video organization
- 📧 **Communication Tools** - Inquiry and newsletter management
      
</td>
  </tr>
</table>

---

## 🚀 Quick Start (5 Minutes!)

Get up and running with ElderCare Connect in just a few commands:

```bash
# 1. Clone the repository
git clone https://github.com/eldercare/connect.git eldercare-connect
cd eldercare-connect

# 2. Copy environment file
cp .env.example .env

# 3. Start Docker containers
docker-compose up -d

# 4. Install dependencies & setup
docker-compose exec app composer install
docker-compose exec app php artisan key:generate
docker-compose exec app php artisan migrate --seed
docker-compose exec app npm install && npm run build

# 5. Visit your site!
open http://localhost
```

🎉 That's it! You should now see the ElderCare Connect homepage.

**Default Admin Credentials:**

- Email: admin@eldercare.local  
- Password: password123

## 📸 Screenshots

<div align="center">
  <img src="https://via.placeholder.com/400x300/E8F4FD/333333?text=Homepage" alt="Homepage" width="45%" />
  <img src="https://via.placeholder.com/400x300/FFF4E6/333333?text=Services" alt="Services" width="45%" />
  <img src="https://via.placeholder.com/400x300/F0FFF4/333333?text=Booking" alt="Booking" width="45%" />
  <img src="https://via.placeholder.com/400x300/FFF0F5/333333?text=Admin" alt="Admin Dashboard" width="45%" />
</div>

## 🛠️ Technology Stack

<table>
  <tr>
    <th>Category</th>
    <th>Technology</th>
    <th>Purpose</th>
  </tr>
  <tr>
    <td rowspan="3"><b>Backend</b></td>
    <td>Laravel 12</td>
    <td>PHP framework for rapid development</td>
  </tr>
  <tr>
    <td>MariaDB 11.8</td>
    <td>Relational database</td>
  </tr>
  <tr>
    <td>Redis 7.2</td>
    <td>Caching & session storage</td>
  </tr>
  <tr>
    <td rowspan="3"><b>Frontend</b></td>
    <td>Livewire 3.0</td>
    <td>Reactive components without JavaScript complexity</td>
  </tr>
  <tr>
    <td>Alpine.js 3.0</td>
    <td>Lightweight JavaScript for interactivity</td>
  </tr>
  <tr>
    <td>Tailwind CSS 3.4</td>
    <td>Utility-first CSS framework</td>
  </tr>
  <tr>
    <td rowspan="2"><b>DevOps</b></td>
    <td>Docker</td>
    <td>Containerization for consistent environments</td>
  </tr>
  <tr>
    <td>GitHub Actions</td>
    <td>CI/CD automation</td>
  </tr>
</table>

## 📂 Project Structure

```
eldercare-connect/
├── 📁 app/                    # Application logic
│   ├── Domain/               # Domain-driven design modules
│   │   ├── Booking/         # Booking functionality
│   │   ├── Service/         # Service management
│   │   └── Staff/           # Staff profiles
│   ├── Http/                # HTTP layer (controllers, middleware)
│   └── Livewire/            # Livewire components
├── 📁 resources/              # Frontend resources
│   ├── views/               # Blade templates
│   ├── css/                 # Stylesheets
│   └── js/                  # JavaScript files
├── 📁 database/               # Database files
│   ├── migrations/          # Schema migrations
│   └── seeders/             # Sample data
├── 📁 tests/                  # Test suites
├── 📁 docker/                 # Docker configuration
├── 📄 composer.json           # PHP dependencies
├── 📄 package.json            # Node dependencies
└── 📄 docker-compose.yml      # Docker orchestration
```

## 🔧 Development Setup

### Prerequisites

- Docker Desktop 4.0+ ([Download](https://www.docker.com/products/docker-desktop))
- Git 2.0+ ([Download](https://git-scm.com/downloads))
- Code editor (We recommend [VS Code](https://code.visualstudio.com/))

### Detailed Installation

<details>
<summary><b>📋 Step-by-step installation guide</b></summary>

**Clone the repository**

```bash
git clone https://github.com/eldercare/connect.git eldercare-connect
cd eldercare-connect
```

**Configure environment**

```bash
cp .env.example .env
# Edit .env with your settings
nano .env
```

**Build and start containers**

```bash
docker-compose build
docker-compose up -d
```

**Install dependencies**

```bash
# PHP dependencies
docker-compose exec app composer install

# Node dependencies
docker-compose exec app npm install
```

**Initialize database**

```bash
docker-compose exec app php artisan key:generate
docker-compose exec app php artisan migrate --seed
docker-compose exec app php artisan storage:link
```

**Build frontend assets**

```bash
docker-compose exec app npm run build
# Or for development with hot reload:
docker-compose exec app npm run dev
```

**Access the application**

- Frontend: http://localhost  
- Admin: http://localhost/admin  
- Mailhog: http://localhost:8025

</details>

## Common Development Tasks

```bash
# Run tests
docker-compose exec app php artisan test

# Run migrations
docker-compose exec app php artisan migrate

# Clear caches
docker-compose exec app php artisan cache:clear

# Watch for frontend changes
docker-compose exec app npm run dev

# Generate IDE helpers
docker-compose exec app php artisan ide-helper:generate

# Format code
docker-compose exec app ./vendor/bin/pint

# Run static analysis
docker-compose exec app ./vendor/bin/phpstan analyse
```

## 🧪 Testing

We maintain high code quality through comprehensive testing:

```bash
# Run all tests
docker-compose exec app php artisan test

# Run specific test suites
docker-compose exec app php artisan test --testsuite=Feature
docker-compose exec app php artisan test --testsuite=Unit

# Run with coverage
docker-compose exec app php artisan test --coverage

# Run browser tests (Dusk)
docker-compose exec app php artisan dusk

# Run frontend tests
docker-compose exec app npm run test
```

### Testing Standards

✅ Minimum 80% code coverage  
✅ All features have integration tests  
✅ Critical paths have browser tests  
✅ Accessibility
