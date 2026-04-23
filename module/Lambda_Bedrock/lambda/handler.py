import json
import boto3
import os

bedrock = boto3.client('bedrock-runtime', region_name=os.environ.get('BEDROCK_REGION', 'us-west-2'))

MODEL_ID = os.environ.get('MODEL_ID')

def cors_headers():
    return {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'POST,OPTIONS',
    }

def lambda_handler(event, context):
    if event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return {'statusCode': 200, 'headers': cors_headers(), 'body': ''}

    try:
        body = json.loads(event.get('body', '{}'))
        messages = body.get('messages', [])

        if not messages:
            return {'statusCode': 400, 'headers': cors_headers(), 'body': json.dumps({'error': 'No messages'})}

        user_prompt = messages[-1].get('content', '') if isinstance(messages, list) else messages

        request_body = {
            "prompt": f"<|begin_of_text|><|start_header_id|>user<|end_header_id|>\n\n{user_prompt}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n",
            "max_gen_len": 512,
            "temperature": 0.1,
            "top_p": 0.9
        }

        response = bedrock.invoke_model(
            modelId=MODEL_ID,
            body=json.dumps(request_body),
            contentType='application/json',
            accept='application/json',
        )

        response_body = json.loads(response['body'].read())

        reply = response_body.get('generation', '')

        return {
            'statusCode': 200,
            'headers': cors_headers(),
            'body': json.dumps({'reply': reply})
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': cors_headers(),
            'body': json.dumps({'error': str(e)})
        }
