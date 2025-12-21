# Folder Structure Migration Guide

## Overview
This guide documents the folder structure reorganization to improve code organization and maintainability.

## Import Path Changes

### Core & Config
| Old Path | New Path |
|----------|----------|
| `import 'package:ryde/common/app_colors.dart'` | `import 'package:ryde/core/constants/app_colors.dart'` |
| `import 'package:ryde/firebase_options.dart'` | `import 'package:ryde/config/firebase_options.dart'` |

### Shared (Utils & Services)
| Old Path | New Path |
|----------|----------|
| `import 'package:ryde/utils/*.dart'` | `import 'package:ryde/shared/utils/*.dart'` |
| `import 'package:ryde/services/*.dart'` | `import 'package:ryde/shared/services/*.dart'` |

### Auth Feature
| Old Path | New Path |
|----------|----------|
| `import 'package:ryde/account_module/controllers/auth_controller.dart'` | `import 'package:ryde/features/auth/controllers/auth_controller.dart'` |
| `import 'package:ryde/features/screen/get_started.dart'` | `import 'package:ryde/features/auth/views/get_started.dart'` |
| `import 'package:ryde/features/screen/login_page.dart'` | `import 'package:ryde/features/auth/views/login_page.dart'` |
| `import 'package:ryde/features/screen/signup.dart'` | `import 'package:ryde/features/auth/views/signup.dart'` |

### Account Feature
| Old Path | New Path |
|----------|----------|
| `import 'package:ryde/account_module/controllers/*.dart'` | `import 'package:ryde/features/account/controllers/*.dart'` |
| `import 'package:ryde/account_module/models/*.dart'` | `import 'package:ryde/features/account/models/*.dart'` |
| `import 'package:ryde/account_module/presentation/pages/*.dart'` | `import 'package:ryde/features/account/views/*.dart'` |
| `import 'package:ryde/account_module/presentation/widgets/*.dart'` | `import 'package:ryde/features/account/widgets/*.dart'` |

### Onboarding Feature
| Old Path | New Path |
|----------|----------|
| `import 'package:ryde/features/screen/on_borading_screen.dart'` | `import 'package:ryde/features/onboarding/views/on_boarding_screen.dart'` |
| `import 'package:ryde/features/screen/add_secondarydata.dart'` | `import 'package:ryde/features/onboarding/views/add_secondarydata.dart'` |

### Ride Feature
| Old Path | New Path |
|----------|----------|
| `import 'package:ryde/features/screen/ride_booking.dart'` | `import 'package:ryde/features/ride/views/ride_booking.dart'` |
| `import 'package:ryde/features/screen/ride_summary.dart'` | `import 'package:ryde/features/ride/views/ride_summary.dart'` |
| `import 'package:ryde/features/screen/ride_tracking_screen.dart'` | `import 'package:ryde/features/ride/views/ride_tracking_screen.dart'` |

### Chat Feature
| Old Path | New Path |
|----------|----------|
| `import 'package:ryde/features/screen/chat.dart'` | `import 'package:ryde/features/chat/views/chat.dart'` |

### Payment Feature
| Old Path | New Path |
|----------|----------|
| `import 'package:ryde/account_module/presentation/pages/paymentgateways.dart'` | `import 'package:ryde/features/payment/views/paymentgateways.dart'` |
| `import 'package:ryde/account_module/presentation/pages/wallet.dart'` | `import 'package:ryde/features/payment/views/wallet.dart'` |

## New Folder Structure

```
lib/
├── config/                          # Configuration files
│   └── firebase_options.dart
│
├── core/                            # Core app functionality
│   ├── constants/
│   │   └── app_colors.dart
│   ├── routes/
│   └── theme/
│
├── features/                        # Feature modules
│   ├── account/                     # Account management
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── views/
│   │   └── widgets/
│   │
│   ├── auth/                        # Authentication
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── views/
│   │   └── widgets/
│   │
│   ├── chat/                        # Chat functionality
│   │   ├── controllers/
│   │   ├── views/
│   │   └── widgets/
│   │
│   ├── onboarding/                  # Onboarding screens
│   │   ├── controllers/
│   │   ├── views/
│   │   └── widgets/
│   │
│   ├── payment/                     # Payment & wallet
│   │   ├── controllers/
│   │   ├── views/
│   │   └── widgets/
│   │
│   ├── ride/                        # Ride management
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── views/
│   │   └── widgets/
│   │
│   ├── car/                         # Car listings (car-screen)
│   │   ├── models/
│   │   ├── views/
│   │   └── widgets/
│   │
│   └── home/                        # Home screen
│       ├── controllers/
│       ├── models/
│       ├── views/
│       └── widgets/
│
├── shared/                          # Shared across features
│   ├── models/
│   ├── services/
│   ├── utils/
│   └── widgets/
│
├── addata.dart
└── main.dart
```

## Migration Steps

1. ✅ Created new folder structure
2. ✅ Copied files to new locations
3. ⏳ Update import statements (in progress)
4. ⏳ Test compilation
5. ⏳ Remove old folders after verification

## Notes

- Old folders (`account_module`, `common`, `utils`, `services`, `features/screen`) are kept temporarily
- After all imports are updated and tested, old folders can be safely deleted
- The `features/car-screen` and `features/home` structures remain in place but can be migrated similarly if needed
