import logging
from logging.handlers import RotatingFileHandler


class CustomFormatter(logging.Formatter):
    def format(self, record):
        # Add class name if available
        class_name = ''
        if hasattr(record, 'classname'):
            class_name = record.classname
        else:
            class_name = ''
        record.classname = class_name
        record.filename = record.pathname.split('/')[-1]
        record.funcname = record.funcName
        return super().format(record)


LOG_FORMAT = '[%(asctime)s] %(levelname)s %(filename)s:%(lineno)d %(classname)s %(funcname)s: %(message)s'
DATE_FORMAT = '%y-%m-%d %H:%M:%S'
LOG_FILE = 'smashremix_extra.log'


def get_logger(name=None):
    logger = logging.getLogger(name)
    if not logger.handlers:
        handler = logging.StreamHandler()
        formatter = CustomFormatter(LOG_FORMAT, DATE_FORMAT)
        handler.setFormatter(formatter)
        logger.addHandler(handler)

        file_handler = RotatingFileHandler(
            LOG_FILE,
            mode='a',
            maxBytes=5 * 1024 * 1024,  # 5 MB
            backupCount=5,
            encoding='utf-8'
        )
        file_handler.setFormatter(CustomFormatter(LOG_FORMAT, DATE_FORMAT))
        logger.addHandler(file_handler)
    logger.setLevel(logging.INFO)
    return logger


logger = get_logger(__name__)
