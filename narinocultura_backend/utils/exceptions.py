from rest_framework.exceptions import APIException


class BusinessLogicError(APIException):
    status_code = 400
    default_detail = "No fue posible procesar la solicitud."
    default_code = "business_logic_error"


class PaymentProviderError(APIException):
    status_code = 502
    default_detail = "Error al comunicarse con el proveedor de pagos."
    default_code = "payment_provider_error"

