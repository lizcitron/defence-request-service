ActionMailer::Base.register_interceptor(SandboxEmailInterceptor) if Settings.sandbox_email