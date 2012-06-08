{
    "name": "case",
    "title": "Кейс",
    "canCreate": true,
    "canRead": true,
    "canUpdate": true,
    "canDelete": true,
    "defaults": {
        "caseStatus": "s0",
        "callerOwner": "1"
    },
    "applications": [
        {
            "targets": [
                "caseAddress_address"
            ],
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ],
            "meta": {
                "label": "Адрес места поломки"
            }
        },
        {
            "targets": [
                "caller_name"
            ],
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ],
            "meta": {
                "label": "Звонящий"
            }
        },
        {
            "targets": [
                "owner_name"
            ],
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ],
            "meta": {
                "label": "Владелец"
            }
        },
        {
            "targets": [
                "cardNumber_cardNumber"
            ],
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ],
            "meta": {
                "label": "Карта участника",
                "infoText": "cardnum"
            }
        },        
        {
            "targets": [
                "caseAddress_coords",
                "caseAddress_city",
                "caseAddress_comment"
            ],
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ]
        },
        {
            "targets": [
                "caller_email",
                "caller_phone1",
                "caller_phone2",
                "caller_phone3",
                "caller_phone4"
            ],
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ]
        },
        {
            "targets": [
                "owner_email",
                "owner_phone1",
                "owner_phone2",
                "owner_phone3",
                "owner_phone4"
            ],
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ]
        },
        {
            "targets": [
                "car_model"
            ],
            "meta": {
                "dictionaryParent": "car_make"
            }
        },
        {
            "targets": [
                "car_vin",
                "car_seller",
                "car_make",
                "car_model",
                "car_plateNum",
                "car_color",
                "car_transmission",
                "car_engine",
                "car_liters",
                "car_capacity",
                "car_dims",
                "car_weight",
                "car_checkPeriod",
                "car_class",
                "car_buyDate",
                "car_mileage",
                "car_checkupDate",
                "car_checkupMileage",
                "car_dealerTO"
            ],
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ]
        },
        {
            "targets": [
                "cardNumber_validFrom",
                "cardNumber_validUntil",
                "cardNumber_validUntilMilage",
                "cardNumber_milageTO",
                "cardNumber_serviceInterval",
                "cardNumber_cardOwner",
                "cardNumber_manager"
            ],
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ]
        },
        {
            "targets": [
                "car_plateNum"
            ],
            "meta": {
                "mainToo": true,
                "infoText": "platenum"
            }
        }
    ],
    "fields": [
        {
            "name": "callDate",
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "head"
            ],
            "index": true,
            "indexCollate": true,
            "type": "datetime",
            "meta": {
                "label": "Дата звонка",
                "readonly": true
            }
        },
        {
            "name": "callTaker",
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "meta": {
                "label": "Сотрудник РАМК",
                "required": true,
                "readonly": true
            }
        },
        {
            "name": "comment",
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ],
            "type": "dictionary",
            "meta": {
                "dictionaryName": "Wazzup",
                "label": "Что случилось",
                "infoText": "comment"
            }
        },
        {
            "name": "diagnosis1",
            "canRead": [
                "front",
                "back",
                "head"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ],
            "type": "dictionary",
            "meta": {
                "dictionaryName": "Diagnosis1",
                "label": "Система",
                "infoText": "system"
            }
        },
        {
            "name": "diagnosis2",
            "canRead": [
                "front",
                "back",
                "head"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ],
            "type": "dictionary",
            "meta": {
                "dictionaryName": "Diagnosis2",
                "dictionaryParent": "diagnosis1",
                "label": "Узел/деталь",
                "infoText": "detail"
            }
        },
        {
            "name": "diagnosis3",
            "canRead": [
                "front",
                "back",
                "head"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ],
            "type": "dictionary",
            "meta": {
                "dictionaryName": "Diagnosis3",
                "dictionaryParent": "diagnosis2",
                "label": "Описание причины неисправности",
                "infoText": "diagnosis3"
            }
        },
        {
            "name": "diagnosis4",
            "canRead": [
                "front",
                "back",
                "head"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ],
            "type": "dictionary",
            "meta": {
                "dictionaryName": "Diagnosis4",
                "label": "Рекомендация",
                "infoText": "recomendation"
            }
        },
        {
            "name": "caller",
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ],
            "groupName": "contact",
            "meta": {
                "label": "Клиент",
                "infoText": "caller"
            }
        },
        {
            "name": "callerOwner",
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "head"
            ],
            "type": "checkbox",
            "meta": {
                "label": "Звонящий владелец?",
                "infoText": "owner"
            }
        },
        {
            "name": "owner",
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ],
            "groupName": "contact",
            "meta": {
                "label": "Владелец",
                "infoText": "ownerName"
            }
        },
        {
            "name": "car",
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ],
            "groupName": "car"
        },
        {
            "name": "cardNumber",
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ],
            "groupName": "cardNumber"
        },
        {
            "name": "program",
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ],
            "index": true,
            "type": "dictionary",
            "meta": {
                "dictionaryName": "Programs",
                "label": "Программа",
                "required": true,
                "targetCategory": "program",
                "infoText": "program"
            }
        },
        {
            "name": "vinChecked",
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ],
            "type": "dictionary",
            "meta": {
                "dictionaryName": "VINChecked",
                "label": "VIN проверен",
                "infoText": "vinChecked"
            }
        },
        {
            "name": "caseAddress",
            "groupName": "address"
        },
        {
            "name": "city",
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "type": "dictionary",
            "meta": {
                "dictionaryName": "DealerCities",
                "label": "Город",
                "infoText": "city"
            }
        },
        {
            "name": "temperature",
            "canRead": [
                "front",
                "back",
                "head"
            ],
            "canWrite": [
                "front",
                "back",
                "head"
            ],
            "meta": {
                "label": "Температура",
                "infoText": "temperature"
            }
        },
        {
            "name": "dealerCause",
            "canRead": [
                "front",
                "back",
                "head"
            ],
            "canWrite": [
                "back",
                "head"
            ],
            "meta": {
                "label": "Причина неисправности со слов дилера",
                "infoText": "dealerCause"
            },
            "type": "textarea"
        },
        {
            "name": "caseStatus",
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "head"
            ],
            "type": "dictionary",
            "meta": {
                "required": true,
                "dictionaryName": "CaseStatuses",
                "label": "Статус кейса"
            }
        },
        {
            "name": "betaComment",
            "canRead": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "canWrite": [
                "front",
                "back",
                "head",
                "parguy"
            ],
            "meta": {
                "label": "Комментарии",
                "infoText": "betaComment"
            },
            "type": "textarea"
        },
        {
            "name": "services",
            "canRead": true,
            "canWrite": true,
            "type": "reference",
            "meta": {
                "label": "Услуги"
            }
        },
        {
            "name": "actions",
            "canRead": true,
            "canWrite": true,
            "type": "reference",
            "meta": {
                "label": "Действия",
                "invisible": true
            }
        }
    ]
}
