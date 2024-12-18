{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AssumeInto",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "${aws_role_arn}"
        }
    ]
}