import base64
import os
import runpod
import time
authorization = os.environ.get("SERVERLESS_API")

with open("/Users/alexholst/Desktop/ITU-Years/Third-year/Six/BSc_Project_VR/FrontEnd/Images/2026-03-19 16:23:58.289016.png", "rb") as image_file:
    encoded_string = base64.b64encode(image_file.read()).decode("utf-8")

data = {"image": encoded_string}

endpoint = runpod.Endpoint("aamisvz3itx91m", authorization)

run_request = endpoint.run(data)

while True:
    status = run_request.status()
    print(status)
    
    if status == "COMPLETED":
        break
    if status in {"FAILED", "CANCELLED", "TIMED_OUT"}:
        raise RuntimeError("Job ended with status: " + status)
    time.sleep(30)
    
print(run_request.output())