import { Component, computed, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-root',
  imports: [FormsModule],
  templateUrl: './app.html',
  styleUrl: './app.scss',
})
export class App {
  protected readonly title = signal('angular-prod');

  protected readonly name = signal('');
  protected readonly greeting = computed(() => {
    const trimmed = this.name().trim();
    return trimmed.length > 0 ? `Welcome, ${trimmed}!` : 'Type your name to get a greeting.';
  });

  protected readonly count = signal(0);

  protected increment(): void {
    this.count.update((value) => value + 1);
  }

  protected decrement(): void {
    this.count.update((value) => value - 1);
  }

  protected reset(): void {
    this.count.set(0);
  }
}
