import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { Counter, Histogram } from 'prom-client';
import { InjectMetric } from '@willsoto/nestjs-prometheus';

@Injectable()
export class MetricsInterceptor implements NestInterceptor {
  constructor(
    @InjectMetric('http_request_duration_seconds')
    private readonly httpRequestDuration: Histogram,
    @InjectMetric('http_requests_total')
    private readonly httpRequestsTotal: Counter,
  ) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const response = context.switchToHttp().getResponse();
    const startTime = Date.now();

    return next.handle().pipe(
      tap({
        next: () => {
          const duration = (Date.now() - startTime) / 1000; // Convert to seconds
          const { method, route } = request;
          const { statusCode } = response;

          // Record request duration
          this.httpRequestDuration.observe(
            {
              method,
              route: route?.path || request.url,
              status_code: statusCode,
            },
            duration,
          );

          // Increment request counter
          this.httpRequestsTotal.inc({
            method,
            route: route?.path || request.url,
            status_code: statusCode,
          });
        },
        error: (error) => {
          const duration = (Date.now() - startTime) / 1000;
          const { method, route } = request;
          const statusCode = error.status || 500;

          // Record error duration
          this.httpRequestDuration.observe(
            {
              method,
              route: route?.path || request.url,
              status_code: statusCode,
            },
            duration,
          );

          // Increment error counter
          this.httpRequestsTotal.inc({
            method,
            route: route?.path || request.url,
            status_code: statusCode,
          });
        },
      }),
    );
  }
}
